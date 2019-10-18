module hand

open DiffSharp.AD.Float64
open DotnetRunner.Data
open System.Composition
open DiffSharp.Util

let angleAxisToRotationMatrix (angleAxis: DV): DM =
    let n = DV.l2norm angleAxis
    if n < D 0.0001 then DM.init 3 3 (fun i j -> if i = j then 1.0 else 0.0) // 3x3 identity matrix
    else
        let x = angleAxis.[0] / n
        let y = angleAxis.[1] / n
        let z = angleAxis.[2] / n
        let s = sin n
        let c = cos n
        DM.ofArray 3 [|
            x * x + (1 - x * x) * c; x * y * (1 - c) - z * s; x * z * (1 - c) + y * s;
            x * y * (1 - c) + z * s; y * y + (1 - y * y) * c; y * z * (1 - c) - x * s;
            x * z * (1 - c) - y * s; z * y * (1 - c) + x * s; z * z + (1 - z * z) * c
        |]

let applyGlobalTransform (poseParams: DV array) (positions: DM): DM =
    ((angleAxisToRotationMatrix poseParams.[0]) |> DM.mapRows ((.*) poseParams.[1])) * positions + poseParams.[2]

let relativesToAbsolutes (relatives: DM array) (parents: int array): DM array =
    // TODO: try mutable array
    Array.fold2 (fun (state: DM list * int) (relative: DM) (parent: int) ->
        let reversedAbsolutes, lastIdx = state
        if parent = -1 then relative :: reversedAbsolutes, lastIdx + 1
        else reversedAbsolutes.[lastIdx - parent] * relative :: reversedAbsolutes, lastIdx + 1
    ) ([], -1) relatives parents |> fst |> List.rev |> Array.ofList

let eulerAnglesToRotationMatrix (xzy: DV): DM =
    let tx = xzy.[0]
    let ty = xzy.[2]
    let tz = xzy.[1]
    let costx = cos(tx)
    let sintx = sin(tx)
    let costy = cos(ty)
    let sinty = sin(ty)
    let costz = cos(tz)
    let sintz = sin(tz)
    DM.ofArray 4 [|
        costy * costz;  -costx * sintz + sintx * sinty * costz; sintx * sintz + costx * sinty * costz;  D 0.0;
        costy * sintz;  costx * costz + sintx * sinty * sintz;  -sintx * costz + costx * sinty * sintz; D 0.0;
        -sinty;         sintx * costy;                          costx * costy;                          D 0.0;
        D 0.0;          D 0.0;                                  D 0.0;                                  D 1.0
    |]
    // The matrix above should have been produced by the code below, instead of being written out explicitly.
    // However, the following code produced the correct objective, but, for some reason, a wrong jacobian.
    //let Rx = toDM [ [ D 1.0; D 0.0; D 0.0 ]; [ D 0.0; costx; -sintx ]; [ D 0.0; sintx; costx ] ]
    //let Ry = toDM [ [ costy; D 0.0; sinty ]; [ D 0.0; D 1.0; D 0.0 ]; [ -sinty; D 0.0; costy ] ]
    //let Rz = toDM [ [ costz; -sintz; D 0.0 ]; [ sintz; costz; D 0.0 ]; [ D 0.0; D 0.0; D 1.0 ] ]
    //Rz * Ry * Rx |> DM.appendCol (DV.zeroCreate 3) |> DM.appendRow (DV [| 0.0; 0.0; 0.0; 1.0 |])

let getPosedRelatives (model: HandModel) (poseParams: DV array): DM array =
    let lastBoneIdx = model.BoneNames.Length - 1
    let offset = 3
    [| for i in 0..lastBoneIdx -> DM model.BaseRelatives.[i] * eulerAnglesToRotationMatrix poseParams.[i + offset] |]

let getSkinnedVertexPositions (model: HandModel) (poseParams: DV array) (applyGlobal: bool) =
    let relatives = getPosedRelatives model poseParams
    let absolutes = relativesToAbsolutes relatives model.Parents
    let transforms = Array.map2 (*) absolutes (Array.map DM model.InverseBaseAbsolutes)
    let basePositions = DM model.BasePositions
    let positions = Array.fold2 (fun (pos: DM) (transform: DM) (weights: float array) ->
        pos + (transform.[0..2, *] * basePositions |> DM.mapRows ((.*) (DV weights)))) (DM.zeroCreate 3 (model.BasePositions.GetLength(1))) transforms model.Weights

    let positions = if model.IsMirrored then DM.mapiRows (fun i row -> if i = 0 then -row else row) positions
                    else positions

    if applyGlobal then applyGlobalTransform poseParams positions
    else positions

let toPoseParams (theta: DV) (nBones: int): DV array =
    let n = 3 + nBones
    let nFingers = 5
    let cols = 5 + nFingers * 4
    Array.init n (fun i -> match i with
                            | 0 -> theta.[0..2]
                            | 1 -> DV [| 1.0; 1.0; 1.0 |]
                            | 2 -> theta.[3..5]
                            | j when j >= cols || j = 3 || j % 4 = 0 -> DV.zeroCreate 3
                            | j when j % 4 = 1 -> DV.append theta.[j + 1..j + 2] (DV.zeroCreate 1) //   toDV [| theta.[j + 1]; theta.[j + 2]; D 0.0 |]
                            | j -> DV.append theta.[j + 2..j + 2] (DV.zeroCreate 2))// toDV [| theta.[j + 2]; D 0.0; D 0.0 |])

let handObjectiveSimple (model: HandModel) (correspondences: int array) (points: DV array) (theta: DV): DV =
    let poseParams = toPoseParams theta model.BoneNames.Length
    let vertexPositions = getSkinnedVertexPositions model poseParams true
    Seq.map2 (fun point correspondence -> point - vertexPositions.[*, correspondence]) points correspondences |> DV.concat

let handObjectiveComplicated (model: HandModel) (correspondences: int array) (points: DV array) (theta: DV) (allUs: DV) : DV =
    let poseParams = toPoseParams theta model.BoneNames.Length
    let vertexPositions = getSkinnedVertexPositions model poseParams true
    let uSeq = DV.splitEqual correspondences.Length allUs
    Seq.map3 (fun point correspondence (u: DV) ->
        let verts = model.Triangles.[correspondence]
        let handPoint = u.[0] * vertexPositions.[*, verts.[0]] + u.[1] * vertexPositions.[*, verts.[1]] +
                            (1.0 - u.[0] - u.[1]) * vertexPositions.[*, verts.[2]]
        point - handPoint) points correspondences uSeq |> DV.concat

[<Export(typeof<DotnetRunner.ITest<HandInput, HandOutput>>)>]
type DiffSharpHand() =
    [<DefaultValue>] val mutable input : HandInput
    [<DefaultValue>] val mutable packedInput : DV
    [<DefaultValue>] val mutable handObjectiveWrapper : DV -> DV
    let mutable objective : DV = DV.empty
    let mutable j : DM = DM.empty

    let mutable isComplicated : bool = false
     
    interface DotnetRunner.ITest<HandInput, HandOutput> with
        member this.Prepare(input: HandInput): unit = 
            this.input <- input
            match input.Us with
            | null ->
                this.packedInput <- DV input.Theta
                let dvPoints = Array.map toDV input.Points
                this.handObjectiveWrapper <- handObjectiveSimple input.Model input.Correspondences dvPoints
            | us ->
                this.packedInput <- DV.append (DV input.Theta) (Seq.map toDV us |> DV.concat)
                let dvPoints = Array.map toDV input.Points
                let thetaCount = input.Theta.Length
                this.handObjectiveWrapper <- (fun par ->
                    let theta = par.[0..thetaCount - 1]
                    let allUs = par.[thetaCount..]
                    handObjectiveComplicated input.Model input.Correspondences dvPoints theta allUs)
            //this.packedInput <- Array.map toDV (Array.concat [ [| input.Alphas |]; input.Means; input.Icf ]) |> DV.concat
            //let icfStartIndex = input.K + input.D * input.K
            //let xDM = input.X |> Seq.ofArray |> Seq.map Seq.ofArray |> toDM
            //this.gmmObjectiveWrapper <- (fun par ->
            //    let alphas = par.[0..input.K - 1]
            //    let means = DV.splitEqual input.K par.[input.K..icfStartIndex - 1] |> DM.ofRows
            //    let icf = DV.splitEqual input.K par.[icfStartIndex..] |> DM.ofRows
            //    gmmObjective alphas means icf xDM input.Wishart.Gamma input.Wishart.M)
            //// Let's build DiffSharp internal Reverse AD Trace
            //// To do it just calculate the function in the another point
            //// Moreover, it forces JIT-compiler to compile the function
            //let oldInput = this.packedInput
            //this.packedInput <- this.packedInput + 1.
            //(this :> DotnetRunner.ITest<GMMInput, HandOutput>).CalculateObjective(1)
            //(this :> DotnetRunner.ITest<GMMInput, HandOutput>).CalculateJacobian(1)
            // Put the old input back 
            //this.packedInput <- oldInput

        member this.CalculateObjective(times: int): unit =
            [1..times] |> List.iter (fun _ ->
                objective <- this.handObjectiveWrapper this.packedInput
            )

        member this.CalculateJacobian(times: int): unit =
            [1..times] |> List.iter (fun _ ->
                j <- jacobian this.handObjectiveWrapper this.packedInput
            )
            
        member this.Output(): HandOutput = 
            let mutable output = new HandOutput()
            output.Objective <- convert objective
            match this.input.Us with
            | null ->
                output.Jacobian <- j.GetRows () |> Seq.map convert |> Array.ofSeq
            | us ->
                let thetaCount = this.input.Theta.Length
                let uCount = us.Length
                let compression = DM.init (thetaCount + 2 * uCount) (thetaCount + 2)
                                    (fun i j -> if (i < thetaCount && j >= 2 && i + 2 = j) || (i >= thetaCount && j < 2 && (i - thetaCount - j) % 2 = 0) then 1.0 else 0.0)
                output.Jacobian <- (j * compression).GetRows () |> Seq.map convert |> Array.ofSeq
            output