module gmm

open DiffSharp.AD.Float64
open DotnetRunner.Data
open System.Composition
open DiffSharp.Util

let unpackQ (logdiag: DV) (lt: DV): DM =
    let d = logdiag.Length
    DM.init d d (fun i j ->
                    if i < j then D 0.
                    else if i = j then exp logdiag.[i]
                    else lt.[d * j + i - j - 1 - j * (j + 1) / 2])

let logGammaDistrib a p = 0.25 * float(p) * float(p - 1) * log System.Math.PI + ([1..p] |> List.sumBy (fun j -> log (MathNet.Numerics.SpecialFunctions.Gamma (a + 0.5 * float(1 - j)))))

let logWishartPrior (qsAndSums: (DM * D) array) wishartGamma wishartM p =
    let k = qsAndSums.Length
    let n = p + wishartM + 1
    let c = float(n * p) * (log wishartGamma - 0.5 * log 2.) - (logGammaDistrib (0.5 * float n) p)
    let frobenius = qsAndSums |> Array.sumBy (fun qAndSum ->
        let q = fst qAndSum
        q.GetRows () |> Seq.sumBy DV.l2normSq)

    let sumQs = qsAndSums |> Array.sumBy snd

    0.5 * wishartGamma * wishartGamma * frobenius - float wishartM * sumQs - float k * c

let gmmObjective (alphas: DV) (means: DM) (icf: DM) (x: DM) (wishartGamma: float) (wishartM: int) =
    let d = x.Cols
    let n = x.Rows
    let constant = - float n * float d * 0.5 * log (2. * System.Math.PI)
    let alphasAndMeans = Seq.zip (alphas.ToArray ()) (means.GetRows ()) |> Array.ofSeq
    let qsAndSums = icf.GetRows ()
                    |> Seq.map (fun (v:DV) ->
                        let logdiag = v.[0..d - 1]
                        let lt = v.[d..]
                        unpackQ logdiag lt, DV.Sum logdiag)
                    |> Array.ofSeq

    let slse = x.GetRows ()
                |> Seq.sumBy (fun xi ->
                    let sumexp = Array.fold2 (fun cursumexp qAndSum alphaAndMeans ->
                        let q, sumQ = qAndSum
                        let alpha, meansk = alphaAndMeans
                        cursumexp + exp (-0.5 * (DV.l2normSq (q * (xi - meansk))) + alpha + sumQ)) (D 0.) qsAndSums alphasAndMeans
                    log sumexp)

    constant + slse  - float(n) * logsumexp alphas + logWishartPrior qsAndSums wishartGamma wishartM d

[<Export(typeof<DotnetRunner.ITest<GMMInput, GMMOutput>>)>]
type DiffSharpBA() =
    [<DefaultValue>] val mutable input : GMMInput
    [<DefaultValue>] val mutable packedInput : DV
    [<DefaultValue>] val mutable gmmObjectiveWrapper : DV -> D
    let mutable objective : D = D 0.
    let mutable gradient : DV = DV.empty
     
    interface DotnetRunner.ITest<GMMInput,GMMOutput> with
        member this.Prepare(input: GMMInput): unit = 
            this.input <- input
            this.packedInput <- Array.map toDV (Array.concat [ [| input.Alphas |]; input.Means; input.Icf ]) |> DV.concat
            let icfStartIndex = input.K + input.D * input.K
            let xDM = input.X |> Seq.ofArray |> Seq.map Seq.ofArray |> toDM
            this.gmmObjectiveWrapper <- (fun par ->
                let alphas = par.[0..input.K - 1]
                let means = DV.splitEqual input.K par.[input.K..icfStartIndex - 1] |> DM.ofRows
                let icf = DV.splitEqual input.K par.[icfStartIndex..] |> DM.ofRows
                gmmObjective alphas means icf xDM input.Wishart.Gamma input.Wishart.M)
            // Let's build DiffSharp internal Reverse AD Trace
            // To do it just calculate the function in the another point
            // Moreover, it forces JIT-compiler to compile the function
            let oldInput = this.packedInput
            this.packedInput <- this.packedInput + 1.
            (this :> DotnetRunner.ITest<GMMInput,GMMOutput>).CalculateObjective(1)
            (this :> DotnetRunner.ITest<GMMInput,GMMOutput>).CalculateJacobian(1)
            // Put the old input back 
            this.packedInput <- oldInput

        member this.CalculateObjective(times: int): unit =
            [1..times] |> List.iter (fun _ ->
                objective <- this.gmmObjectiveWrapper this.packedInput
            )

        member this.CalculateJacobian(times: int): unit =
            [1..times] |> List.iter (fun _ ->
                gradient <- grad this.gmmObjectiveWrapper this.packedInput
            )
            
        member this.Output(): GMMOutput = 
            let mutable output = new GMMOutput()
            output.Objective <- convert objective
            output.Gradient <- convert gradient
            output