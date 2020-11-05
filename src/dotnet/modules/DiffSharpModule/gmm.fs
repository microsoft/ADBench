module gmm

open System
open DiffSharp
open DotnetRunner.Data
open System.Composition
open DiffSharp.Util
open utils

(*
open utils

type D = Tensor
type DV = Tensor
type DM = Tensor

let frobeniusNormSq (m: DM) = dsharp.sum(m*m)

let unpackQ (logdiag: DV) (lt: DV) : DM =
    //let d = logdiag.Length
    let d = logdiag.shape.Length
   
    dsharp.init2d d d (fun i j ->
        if i < j then dsharp.tensor 0.
        else if i = j then exp logdiag.[i]
        else lt.[d * j + i - j - 1 - j * (j + 1) / 2])

let logGammaDistrib a p =
    0.25 * float(p) * float(p - 1) * log System.Math.PI +
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

    let d = x.shape.[1] //TODO: check dimension ordering
    let n = x.shape.[0]

    let constant = - float n * float d * 0.5 * log (2. * System.Math.PI)

    let alphasAndMeans = Array.zip (alphas.toArray() :?> DV[]) means
    let qsAndSums = 
        icf |> Array.map (fun (v:DV) ->
            let logdiag = v.[0..d - 1]
            let lt = v.[d..]
            unpackQ logdiag lt, dsharp.sum logdiag)

    let slse = x.GetRows ()
                |> Seq.sumBy (fun xi ->
                    (qsAndSums,alphasAndMeans)
                    ||> Array.map2
                        (fun qAndSum alphaAndMeans ->
                            let q, sumQ = qAndSum
                            let alpha, meansk = alphaAndMeans
                            -0.5 * (DV.l2normSq (q * (xi - meansk))) + alpha + sumQ
                        ) 
                    |> logsumexp_DArray)

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
*)

let logsumexp(x) =
    let mx = dsharp.max(x)
    let emx = dsharp.exp(x - mx)
    dsharp.log(dsharp.sum(emx)) + mx


/// The same as "logsumexp" but calculates result for each row separately.
let logsumexpvec(x) =

    let mx = dsharp.max(x, 1)
    let lset = dsharp.logsumexp(dsharp.transpose(x) - mx, 0)
    dsharp.transpose(lset + mx)


let multigammaln(a, d: int) =
    let mutable res = (float d * (float d - 1.0) * 0.25) * log(Math.PI)
    res <- res + float (dsharp.sum(dsharp.tensor([for j in 1..d -> MathNet.Numerics.SpecialFunctions.GammaLn(float a - ((float j - 1.0) / 2.0)) ]),dim=0))
    res

let log_gamma_distrib(a, p) = multigammaln(a, p)


let sqsum(x) =
    dsharp.sum(x ** 2)


let log_wishart_prior(p: int, wishart_gamma: float, wishart_m: int, sum_qs: float, qdiags, icf: Tensor) =
    let n = p + wishart_m + 1
    let k = icf.shape.[0]

    let out = dsharp.sum(0.5 * wishart_gamma * wishart_gamma * (dsharp.sum(qdiags ** 2, dim = 1) + dsharp.sum(icf.[*,p..] ** 2, dim = 1)) - float wishart_m * sum_qs)

    let C = float n * float p * (log(wishart_gamma / sqrt(2.0)))
    out - float k * (C - log_gamma_distrib(0.5 * float n, p))


let make_L_col_lifted(d: int, icf: Tensor, constructL_Lparamidx: int, i: int) =
    let nelems = d - i - 1
    let col = dsharp.cat([ dsharp.zeros(i + 1, dtype=Dtype.Float64); icf.[constructL_Lparamidx .. (constructL_Lparamidx + nelems - 1)]])

    let constructL_Lparamidx = constructL_Lparamidx + nelems
    (constructL_Lparamidx, col)

let constructL(d, icf) =
    let mutable constructL_Lparamidx = d

    let columns = ResizeArray()
    for i in 0..d-1 do
        let constructL_Lparamidx_update, col = make_L_col_lifted(d, icf, constructL_Lparamidx, i)
        columns.Add(col)
        constructL_Lparamidx <- constructL_Lparamidx_update

    dsharp.stack(columns, -1)


let Qtimesx(qdiags, L, x) =
    let f = dsharp.einsum("ijk,mik->mij", L, x)
    qdiags * x + f


let gmm_objective(alphas: Tensor, means: Tensor, icf: Tensor, x: Tensor, wishart_gamma, wishart_m) =
    let n = x.shape.[0]
    let d = x.shape.[1]

    let qdiags = dsharp.exp(icf.[*, 0..d-1])
    let sum_qs = dsharp.sum(icf.[*, 0..d-1], 1) |> float
    let Ls = dsharp.stack([for curr_icf in icf.unstack() -> constructL(d, curr_icf) ])
    
    let xcentered = dsharp.stack([ for i in 0..n-1 -> x.[i,*] - means ])
    let Lxcentered = Qtimesx(qdiags, Ls, xcentered)
    let sqsum_Lxcentered = dsharp.sum(Lxcentered ** 2, 2) |> float
    let inner_term = alphas + sum_qs - 0.5 * sqsum_Lxcentered
    let lse = logsumexpvec(inner_term)
    let slse = dsharp.sum(lse)

    let CONSTANT = float -n * float d * 0.5 * log(2.0 * Math.PI)
    CONSTANT + slse - n * logsumexp(alphas) + log_wishart_prior(d, wishart_gamma, wishart_m, sum_qs, qdiags, icf)
