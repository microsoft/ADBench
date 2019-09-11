module ba

open System
open System.Diagnostics
open System.IO

open DiffSharp.AD.Float64
open DotnetRunner.Data

let N_CAM_PARAMS = 11
let ROT_IDX = 0
let CENTER_IDX = 3
let FOCAL_IDX = 6
let X0_IDX = 7
let RAD_IDX = 9

let dot (a:DV) (b:DV) = a * b

let cross (a:DV) (b:DV) = 
    toDV [a.[1]*b.[2] - a.[2]*b.[1]; a.[2]*b.[0] - a.[0]*b.[2]; a.[0]*b.[1] - a.[1]*b.[0]]

let rodrigues_rotate_point (rot:DV) (x:DV) =
    let sqtheta = DV.l2normSq rot
    if sqtheta <> D 0. then
        let theta = sqrt sqtheta
        let costheta = cos theta
        let sintheta = sin theta
        let theta_inv = D 1. / theta

        let w = rot * theta_inv
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

let compute_reproj_err (cam:DV) (x:DV) (w:D) (feat:float[]) =
    ((project cam x) - toDV feat) * w

let compute_reproj_err_wrapper (parameters:DV) (feat:float[]) =
    let X_off = N_CAM_PARAMS
    let w_off = X_off + 3
    compute_reproj_err parameters.[..(X_off-1)] parameters.[X_off..(X_off+2)] parameters.[w_off] feat

let vectorize (cam:DV) (x:DV) (w:D) = 
    DV.concat [| cam; x; toDV [| w |] |]

let compute_zach_weight_error (w:D) =
    1. - w*w

let create_sparse_J n m p obs (reproj_err_d:_[,][]) (w_err_d:_[]) =
    let nrows = 2 * p + p;
    let ncols = N_CAM_PARAMS*n + 3 * m + p;

    let toArray (arr: 'T [,]) = arr |> Seq.cast<'T> |> Seq.toArray

    let J = new BASparseMatrix()

    raise (System.NotImplementedException())

    ()

type DiffSharpBA() =

    [<DefaultValue>] val mutable input : BAInput
    [<DefaultValue>] val mutable output : BAOutput
 
    interface DotnetRunner.ITest<BAInput,BAOutput> with
        member this.Prepare(input: BAInput): unit = 
            this.input <- input

        member this.CalculateObjective(times: int): unit = 
            let n = this.input.N
            let p = this.input.P

            let obs = this.input.Obs
            let ds_cams = Array.map toDV this.input.Cams
            let ds_X = Array.map toDV this.input.X
            let ds_w = Array.map D this.input.W

            let reproj_err = 
                [|for i = 0 to p-1 do yield (compute_reproj_err ds_cams.[obs.[i].[0]] ds_X.[obs.[i].[1]] ds_w.[i] this.input.Feats.[i])|]
            let w_err = Array.map compute_zach_weight_error ds_w

            this.output.ReprojErr <- convert (DV.concat reproj_err)
            this.output.WErr <- convert (toDV w_err)

        member this.CalculateJacobian(times: int): unit = 
            let n = this.input.N
            let m = this.input.M
            let p = this.input.P

            let obs = this.input.Obs
            let ds_cams = Array.map toDV this.input.Cams
            let ds_X = Array.map toDV this.input.X
            let ds_w = Array.map D this.input.W

            let compute_reproj_err_J_block (cam:_[]) (x:_[]) (w:_) (feat:float[]) =
                let compute_reproj_err_wrapper parameters = 
                    compute_reproj_err_wrapper parameters feat
                let err_D, J_D = (jacobian' compute_reproj_err_wrapper (vectorize (toDV cam) (toDV x) (D w)))
                let err = convert err_D
                let J = convert J_D
                err, J

            let compute_w_err_d (w:float) = 
                let e,ed = diff' compute_zach_weight_error (D w)
                convert e, convert ed

            let reproj_err_val_J = 
                [|for i=0 to p-1 do 
                    yield compute_reproj_err_J_block this.input.Cams.[obs.[i].[0]] this.input.X.[obs.[i].[1]] this.input.W.[i] this.input.Feats.[i]|]
            let w_err_val_J = Array.map compute_w_err_d this.input.W
            
            let reproj_err, reproj_err_d = Array.unzip reproj_err_val_J
            let w_err, w_err_d = Array.unzip w_err_val_J
            
            let J = create_sparse_J m n p obs reproj_err_d w_err_d

            ()

        member this.Output(): BAOutput = 
            raise (System.NotImplementedException())



