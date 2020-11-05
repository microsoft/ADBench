module ba

(*
open System
open System.Diagnostics
open System.IO

open utils
open DiffSharp
open DotnetRunner.Data
open System.Composition
open DotnetRunner

let N_CAM_PARAMS = 11
let ROT_IDX = 0
let CENTER_IDX = 3
let FOCAL_IDX = 6
let X0_IDX = 7
let RAD_IDX = 9

let dot (a:DV) (b:DV) = a * b

let cross (a:DV) (b:DV) = 
    toDV [ a.[1] * b.[2] - a.[2] * b.[1]; a.[2] * b.[0] - a.[0] * b.[2]; a.[0] * b.[1] - a.[1] * b.[0] ]

let rodrigues_rotate_point (rot:DV) (x:DV) =
    let sqtheta = DV.l2normSq rot
    if sqtheta <> D 0. then
        let theta = sqrt sqtheta
        let costheta = cos theta
        let sintheta = sin theta

        let w = rot / theta
        let w_cross_X = cross w x    
        let tmp = (dot w x) * (D 1. - costheta)

        (x * costheta) + (w_cross_X * sintheta) + (w * tmp)
    else
        x + (cross rot x)

let radial_distort (rad_params:DV) (proj:DV) =
    let rsq = DV.l2normSq proj
    let L = 1. + rad_params.[0] * rsq + rad_params.[1] * rsq * rsq
    proj * L

let proj (x:DV) = x.[0..1] / x.[2]

let project (cam:DV) (x:DV) =
    let rot = cam.[ROT_IDX..(ROT_IDX+2)]
    let translation = cam.[CENTER_IDX..(CENTER_IDX+2)]
    let kappa = cam.[RAD_IDX..(RAD_IDX+1)]
    let principal_point = cam.[X0_IDX..(X0_IDX+1)]
    let focal_length = cam.[FOCAL_IDX]

    let Xcam = rodrigues_rotate_point rot (x - translation)
    let distorted = radial_distort kappa (proj Xcam)
    principal_point + (distorted * focal_length)

let compute_reproj_err (cam:DV) (x:DV) (w:D) (feat:DV) =
    ((project cam x) - feat) * w

let compute_reproj_err_wrapper (parameters:DV) (feat:DV) =
    let X_off = N_CAM_PARAMS
    let w_off = X_off + 3
    compute_reproj_err parameters.[..(X_off-1)] parameters.[X_off..(X_off+2)] parameters.[w_off] feat

let vectorize (cam:DV) (x:DV) (w:D) = 
    DV.concat [| cam; x; toDV [| w |] |]

let compute_zach_weight_error (w:D) =
    1. - w * w

let create_sparse_J n m p (obs:_[][]) (reproj_err_d:_[,][]) (w_err_d:_[]) =
    let nrows = 2 * p + p;
    let ncols = N_CAM_PARAMS*n + 3 * m + p;

    let to1DArray (arr: 'T [,]) =
        seq { for y in [0..(Array2D.length2 arr) - 1] do 
                  for x in [0..(Array2D.length1 arr) - 1] do 
                      yield arr.[x, y] } |> Seq.toArray

    let J = new BASparseMatrix(n, m, p);

    let reproj_iterator i value =
        let camIdx = obs.[i].[0];
        let ptIdx = obs.[i].[1];
        J.InsertReprojErrBlock(i, camIdx, ptIdx, to1DArray value)

    Array.iteri reproj_iterator reproj_err_d  

    let w_iterator i value =
        J.InsertWErrBlock(i, value)

    Array.iteri w_iterator w_err_d

    J

type BADSInput(input:BAInput) =
    member val n:int = input.N
    member val m:int = input.M
    member val p:int = input.P

    member val Cams = Array.map toDV input.Cams
    member val X = Array.map toDV input.X with get, set
    member val W = Array.map D input.W
   
    member val Feats = Array.map toDV input.Feats

    member val Obs = input.Obs

type BADSOutput() =
    [<DefaultValue>] val mutable reproj_err : DV[]
    [<DefaultValue>] val mutable w_err : D[]

    [<DefaultValue>] val mutable reproj_err_val_J : (DV * DM)[] 
    [<DefaultValue>] val mutable w_err_val_J : (D * D)[]


[<Export(typeof<DotnetRunner.ITest<BAInput, BAOutput>>)>]
type DiffSharpBA() =

    [<DefaultValue>] val mutable input : BADSInput

    let output = new BADSOutput()
 
    interface DotnetRunner.ITest<BAInput,BAOutput> with
        member this.Prepare(input: BAInput): unit = 
            this.input <- BADSInput input
            // Let's build DiffSharp internal Reverse AD Trace
            // To do it just calculate the function in the another point
            // Moreover, it forces JIT-compiler to compile the function
            let oldX = this.input.X
            let newX = Array.map (fun x -> x + 1) this.input.X
            this.input.X <- newX
            (this :> ITest<BAInput,BAOutput>).CalculateObjective(1)
            (this :> ITest<BAInput,BAOutput>).CalculateJacobian(1)
            // Turn the old point back 
            this.input.X <- oldX

        member this.CalculateObjective(times: int): unit = 
            let p = this.input.p
            
            let obs = this.input.Obs
            let ds_cams = this.input.Cams
            let ds_X = this.input.X
            let ds_w = this.input.W
            let feats = this.input.Feats

            [1..times] |> List.iter (fun _ ->
                output.reproj_err <- 
                    [| for i = 0 to p-1 do yield (compute_reproj_err ds_cams.[obs.[i].[0]] ds_X.[obs.[i].[1]] ds_w.[i] feats.[i]) |]
                output.w_err <- Array.map compute_zach_weight_error ds_w
             )

        member this.CalculateJacobian(times: int): unit = 
            let p = this.input.p

            let obs = this.input.Obs

            let compute_reproj_err_J_block (cam:DV) (x:DV) (w:D) (feat:DV) =
                let compute_reproj_err_wrapper parameters = 
                    compute_reproj_err_wrapper parameters feat
                (jacobian' compute_reproj_err_wrapper (vectorize cam x w))

            let compute_w_err_d (w:D) = 
                diff' compute_zach_weight_error w

            [1..times] |> List.iter (fun _ ->
                output.reproj_err_val_J <- 
                    [| for i = 0 to p - 1 do 
                        yield compute_reproj_err_J_block this.input.Cams.[obs.[i].[0]] this.input.X.[obs.[i].[1]] this.input.W.[i] this.input.Feats.[i] |]
                output.w_err_val_J <- Array.map compute_w_err_d this.input.W
            )
            
        member this.Output(): BAOutput = 
            let n = this.input.n
            let m = this.input.m
            let p = this.input.p

            let obs = this.input.Obs

            let baOutput = new BAOutput()

            match output.reproj_err, output.w_err with
            | null, null -> 
                baOutput.ReprojErr <- null
                baOutput.WErr <- null
            | _ ->
                baOutput.ReprojErr <- convert (DV.concat output.reproj_err)
                baOutput.WErr <- convert (toDV output.w_err)
            
            match output.reproj_err_val_J, output.w_err_val_J with
            | null, null -> 
                baOutput.J <- null
            | _ ->
                let reproj_err, reproj_err_d = Array.unzip output.reproj_err_val_J
                let w_err, w_err_d = Array.unzip output.w_err_val_J
                
                let J = create_sparse_J n m p obs (Array.map convert reproj_err_d) (Array.map convert w_err_d)
                baOutput.J <- J

            baOutput



*)
