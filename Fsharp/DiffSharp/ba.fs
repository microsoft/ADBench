module ba

open System
open System.Diagnostics
open System.IO

#if MODE_AD
open DiffSharp.AD
#else
open DiffSharp.AD.Specialized.Reverse1
#endif

let N_CAM_PARAMS = 11
let ROT_IDX = 0
let CENTER_IDX = 3
let FOCAL_IDX = 6
let X0_IDX = 7
let RAD_IDX = 9

////// Objective //////

let inline sqnorm (x:_[]) =
    x |> Array.map (fun x -> x*x) |> Array.sum

let inline dot_prod (x:_[]) (y:_[]) =
    Array.map2 (*) x y |> Array.sum

let inline sub_vec (x:_[]) (y:_[]) =
    Array.map2 (-) x y

let inline add_vec (x:_[]) (y:_[]) =
    Array.map2 (+) x y

let inline add_vec3 (x:_[]) (y:_[]) (z:_[]) =
    Array.map3 (fun a b c -> a+b+c) x y z

let inline mult_by_scalar (x:_[]) y =
    Array.map (fun a -> a*y) x

let inline cross (a:_[]) (b:_[]) =
    [|a.[1]*b.[2] - a.[2]*b.[1]; a.[2]*b.[0] - a.[0]*b.[2]; a.[0]*b.[1] - a.[1]*b.[0];|]

let rodrigues_rotate_point (rot:_[]) (X:_[]) =
    let sqtheta = sqnorm rot
    if sqtheta <> 0. then
        let theta = sqrt sqtheta
        let costheta = cos theta
        let sintheta = sin theta
        let theta_inv = 1. / theta

        let w = mult_by_scalar rot theta_inv
        let w_cross_X = cross w X    
        let tmp = (dot_prod w X) * (1. - costheta)

        add_vec3 (mult_by_scalar X costheta) (mult_by_scalar w_cross_X sintheta) (mult_by_scalar w tmp)
    else
        add_vec X (cross rot X)

let radial_distort (rad_params:_[]) (proj:_[]) =
    let rsq = sqnorm proj
    let L = 1. + rad_params.[0] * rsq + rad_params.[1] * rsq * rsq
    mult_by_scalar proj L

let project (cam:_[]) (X:_[]) =
    let Xcam = rodrigues_rotate_point cam.[ROT_IDX..(ROT_IDX+2)] (sub_vec X cam.[CENTER_IDX..(CENTER_IDX+2)])
    let distorted = radial_distort cam.[RAD_IDX..(RAD_IDX+1)] (mult_by_scalar Xcam.[0..1] (1./Xcam.[2]))
    add_vec cam.[X0_IDX..(X0_IDX+1)] (mult_by_scalar distorted cam.[FOCAL_IDX])

let compute_reproj_err (cam:_[]) (X:_[]) w (feat:_[]) =
    mult_by_scalar (sub_vec (project cam X) feat) w

let compute_zach_weight_error w =
    1. - w*w

let ba_objective (cams:_[][]) (X:_[][]) (w:_[]) (obs:int[][]) (feat:float[][]) =
    let n = cams.Length
    let p = w.Length
    let reproj_err = 
        [|for i = 0 to p-1 do yield (compute_reproj_err cams.[obs.[i].[0]] X.[obs.[i].[1]] w.[i] feat.[i])|]
    let w_err = Array.map compute_zach_weight_error w 
    reproj_err, w_err

///// Derivative extras /////
let rodrigues_rotate_point_ (rot:D[]) (X:D[]) =
    let sqtheta = sqnorm rot
    let zero = rot.[0] - rot.[0] // simple (D 0.) did not work
    if sqtheta <> zero then
        let theta = sqrt sqtheta
        let costheta = cos theta
        let sintheta = sin theta
        let theta_inv = 1. / theta

        let w = mult_by_scalar rot theta_inv
        let w_cross_X = cross w X    
        let tmp = (dot_prod w X) * (1. - costheta)

        add_vec3 (mult_by_scalar X costheta) (mult_by_scalar w_cross_X sintheta) (mult_by_scalar w tmp)
    else
        add_vec X (cross rot X)

let radial_distort_ (rad_params:D[]) (proj:D[]) =
    let rsq = sqnorm proj
    let L = 1. + rad_params.[0] * rsq + rad_params.[1] * rsq * rsq
    mult_by_scalar proj L

let project_ (cam:D[]) (X:D[]) =
    let Xcam = rodrigues_rotate_point_ cam.[ROT_IDX..(ROT_IDX+2)] (sub_vec X cam.[CENTER_IDX..(CENTER_IDX+2)])
    let distorted = radial_distort_ cam.[RAD_IDX..(RAD_IDX+1)] (mult_by_scalar Xcam.[0..1] (1./Xcam.[2]))
    add_vec cam.[X0_IDX..(X0_IDX+1)] (mult_by_scalar distorted cam.[FOCAL_IDX])

let compute_reproj_err_ (cam:D[]) (X:D[]) (w:D) (feat:float[]) =
    mult_by_scalar (sub_vec (project_ cam X) feat) w
    
let compute_reproj_err_wrapper (parameters:_[]) (feat:float[]) =
    let X_off = N_CAM_PARAMS
    let w_off = X_off + 3
    compute_reproj_err_ parameters.[..(X_off-1)] parameters.[X_off..(X_off+2)] parameters.[w_off] feat

let vectorize (cam:_[]) (X:_[]) (w:_) = 
    Array.append (Array.append cam X) [|w|]

let compute_zach_weight_error_ (w:D) =
    1. - w*w
    
////// UTILS ////

// TODO
let create_sparse_J n m p obs (reproj_err_d:_[,][]) (w_err_d:_[]) =
    let nrows = 2 * p + p;
    let ncols = N_CAM_PARAMS*n + 3 * m + p;

//    let n_new_cols = N_CAM_PARAMS + 3 + 1
//    let rows1 = [|for i=0 to 2*p-1 do yield i*n_new_cols|];
//    let w_off = n_new_cols*2*p
//    let rows2 = [|for i=0 to p-1 do yield i + w_off+1|];
//    let rows = Array.append (Array.append [|0|] rows1) rows2
    
    (reproj_err_d, w_err_d)
    //(nrows,ncols,rows,cols,vals)

////// IO //////

let read_ba_instance (fn:string) =
    let read_in_elements (fn:string) =
        let string_lines = File.ReadLines(fn)
        let separators = [|' '|]
        [| for line in string_lines do yield line.Split separators |] 
            |> Array.map (Array.filter (fun x -> x.Length > 0))

    let parse_double (arr:string[]) = Array.map Double.Parse arr

    let data = read_in_elements fn

    let n = Int32.Parse data.[0].[0]
    let m = Int32.Parse data.[0].[1]
    let p = Int32.Parse data.[0].[2]
    
    let mutable offset = 1
    let one_cam = parse_double data.[offset]
    let cams = [|for i=1 to n do yield one_cam|]
    offset <- offset + 1

    let one_X = parse_double data.[offset]
    let X = [|for i=1 to m do yield one_X|]
    offset <- offset + 1

    let one_w = Double.Parse data.[offset].[0]
    let w = [|for i=1 to p do yield one_w|]
    offset <- offset + 1

    let one_feat = parse_double data.[offset]
    let feat = [|for i=1 to p do yield one_feat|]

    let mutable camIdx = 0
    let mutable ptIdx = 0
    let obs = [|for i=1 to p do 
                yield [|camIdx; ptIdx|]
                camIdx <- (camIdx+1) % n
                ptIdx <- (ptIdx+1) % m
              |]

    cams, X, w, obs, feat