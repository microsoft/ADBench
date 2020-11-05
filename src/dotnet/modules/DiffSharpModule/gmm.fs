module gmm

open DiffSharp
open DotnetRunner.Data
open System.Composition
open DiffSharp.Util
open utils


type D = Tensor
type DV = Tensor
type DM = Tensor

// let frobeniusNormSq (m: Tensor) = m. () |> Seq.sumBy
// let frobeniusNormSq (m: DM) = m.GetRows () |> Seq.sumBy DV.l2normSq

let unpackQ (logdiag: DV) (lt: DV) : DM =
    //let d = logdiag.Length
    let d = logdiag.shape.Length
   
    dsharp.init2d d d (fun i j ->
                    if i < j then dsharp.tensor 0.
                    else if i = j then exp logdiag.[i]
                    else lt.[d * j + i - j - 1 - j * (j + 1) / 2])

let logGammaDistrib a p = 0.25 * float(p) * float(p - 1) * log System.Math.PI +
                            ([1..p] |> List.sumBy (fun j -> MathNet.Numerics.SpecialFunctions.GammaLn (a + 0.5 * float(1 - j))))

// DV.LogSumExp tries to compute exp(logsumexp arr) in the adjoint,
// which seem to overflow in some of our cases.
// That does not happen when we simply AD an explicit implementation.
let logsumexp_DArray (arr: D[]) =
    let mx = Array.max arr
    let sumShiftedExp = arr |> Array.sumBy (fun x -> exp (x - mx))
    log sumShiftedExp + mx

let logWishartPrior (qsAndSums: (DM * D) array) wishartGamma wishartM p =
    let k = qsAndSums.Length
    let n = p + wishartM + 1
    let c = float(n * p) * (log wishartGamma - 0.5 * log 2.) - (logGammaDistrib (0.5 * float n) p)
    let frobenius = qsAndSums |> Array.sumBy (fst >> frobeniusNormSq)

    let sumQs = qsAndSums |> Array.sumBy snd

    0.5 * wishartGamma * wishartGamma * frobenius - float wishartM * sumQs - float k * c

let gmmObjective (alphas: DV) (means: DV[]) (icf: DV[]) (x: DM) (wishartGamma: float) (wishartM: int) =
    // let d = x.Cols
    // let n = x.Rows

    let d = x.shape.GetLength(1) //TODO: check dimension ordering
    let n = x.shape.GetLength(0)

    let constant = - float n * float d * 0.5 * log (2. * System.Math.PI)

    

    let alphasAndMeans = Array.zip (alphas.toArray() :?> DV[]) means
    let qsAndSums = icf |> Array.map (fun (v:DV) ->
                        let logdiag = v.[0..d - 1]
                        let lt = v.[d..]
                        unpackQ logdiag lt, dsharp.sum logdiag)


    dsharp.sum

    let slse = x.GetRows ()
                |> Seq.sumBy (fun xi ->
                    logsumexp_DArray <| Array.map2
                        (fun qAndSum alphaAndMeans ->
                            let q, sumQ = qAndSum
                            let alpha, meansk = alphaAndMeans
                            -0.5 * (DV.l2normSq (q * (xi - meansk))) + alpha + sumQ
                        ) qsAndSums alphasAndMeans)

    constant + slse - float(n) * logsumexp alphas + logWishartPrior qsAndSums wishartGamma wishartM d

[<Export(typeof<DotnetRunner.ITest<GMMInput, GMMOutput>>)>]
type DiffSharpGMM() =
    inherit DiffSharpModuleBase<GMMInput, GMMOutput>()
    [<DefaultValue>] val mutable input : GMMInput
    [<DefaultValue>] val mutable gmmObjectiveWrapper : DV -> D
    let mutable objective : D = dsharp.tensor 0.
    let mutable gradient : Tensor = dsharp.tensor [||]
     
    override this.Prepare(input: GMMInput) : unit = 
        this.input <- input
        this.packedInput <- Array.map dsharp.tensor (Array.concat [ [| input.Alphas |]; input.Means; input.Icf ]) |> DV.concat //Use view?
        let icfStartIndex = input.K + input.D * input.K
        let xDM = input.X |> Seq.ofArray |> Seq.map Seq.ofArray |> dsharp.tensor

        

        this.gmmObjectiveWrapper <- (fun par ->
            let alphas = par.[0..input.K - 1]
            let means = DV.splitEqual input.K par.[input.K..icfStartIndex - 1] |> Array.ofSeq
            let icf = DV.splitEqual input.K par.[icfStartIndex..] |> Array.ofSeq
            gmmObjective alphas means icf xDM input.Wishart.Gamma input.Wishart.M)
        this.burnIn()

    override this.CalculateObjective(times: int) : unit =
        [1..times] |> List.iter (fun _ ->
            objective <- this.gmmObjectiveWrapper this.packedInput
        )

    override this.CalculateJacobian(times: int) : unit =
        [1..times] |> List.iter (fun _ ->
            gradient <- grad this.gmmObjectiveWrapper this.packedInput
        )
            
    override this.Output() : GMMOutput = 
        let mutable output = new GMMOutput()
        output.Objective <- convert objective
        output.Gradient <- convert gradient
        output