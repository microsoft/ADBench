open System
open System.Diagnostics
open System.IO

#if MODE_AD && (DO_GMM_FULL || DO_GMM_SPLIT)
open DiffSharp.AD
#else
open DiffSharp.AD.Specialized.Reverse1
#endif

let write_times (fn:string) (tf:float) (tJ:float) =
    let line1 = sprintf "%f %f\n" tf tJ
    let line2 = sprintf "tf tJ"
    let lines = [|line1; line2|]
    File.WriteAllLines(fn,lines)

#if (DO_GMM_FULL || DO_GMM_SPLIT)
let test_gmm fn_in fn_out nruns_f nruns_J replicate_point =
    let alphas, means, icf, x, wishart = gmm.read_gmm_instance (fn_in + ".txt") replicate_point
    
    let obj_stop_watch = Stopwatch.StartNew()
    let err = gmm.gmm_objective alphas means icf x wishart
    for i = 1 to nruns_f-1 do
        gmm.gmm_objective alphas means icf x wishart
    obj_stop_watch.Stop()

    let k = alphas.Length
    let d = means.[0].Length
    let n = x.Length
    
#if DO_GMM_FULL
    let gmm_objective_wrapper_ (parameters:_[]) = gmm.gmm_objective_wrapper d k parameters x wishart
    let grad_gmm_objective = grad' gmm_objective_wrapper_
    let grad_func parameters = grad_gmm_objective parameters
  #if MODE_AD
    let name = "DiffSharp"
  #endif
  #if MODE_R
    let name = "DiffSharp_R"
  #endif
#endif
#if DO_GMM_SPLIT
    let gmm_objective_2wrapper_ (parameters:_[]) = gmm.gmm_objective_2wrapper d k n parameters wishart
    let grad_gmm_objective2 = grad' gmm_objective_2wrapper_
    let grad_gmm_objective_split (parameters:_[]) =
        let mutable err, grad = grad_gmm_objective2 parameters
        for i = 0 to n-1 do
            let gmm_objective_1wrapper_ (parameters:_[]) = gmm.gmm_objective_1wrapper d k parameters x.[i]
            let grad_gmm_objective1 = grad' gmm_objective_1wrapper_
            let err_curr, grad_curr = grad_gmm_objective1 parameters
            err <- err + err_curr
            grad <- Array.map2 (+) grad grad_curr
        (err, grad)
    let grad_func parameters = grad_gmm_objective_split parameters
  #if MODE_R
    let name = "DiffSharp_R_split"
  #endif
#endif

    let grad_stop_watch = Stopwatch.StartNew()
    if nruns_J>0 then   
        let parameters = (gmm.vectorize alphas means icf) 
#if MODE_AD
                            |> Array.map D
#endif
        let err2, gradient = (grad_func parameters)
        for i = 1 to nruns_J-1 do
            grad_func parameters
        grad_stop_watch.Stop()
    
        gmm.write_grad (fn_out + "_J_" + name + ".txt") gradient   

    let tf = ((float obj_stop_watch.ElapsedMilliseconds) / 1000.) / (float nruns_f)
    let tJ = ((float grad_stop_watch.ElapsedMilliseconds) / 1000.) / (float nruns_J)
    write_times (fn_out + "_times_" + name + ".txt") tf tJ
//    printfn "tf: %f" tf
//    printfn "tJ: %f" tJ
//    printfn "tJ/tf: %f" (tJ/tf)

//let test_ba fn nruns = 
//    let cams, X, w, obs, feat = ba.read_ba_instance (fn + ".txt")

//    let nruns = 1000
//
////    let reproj_err, f_prior_err, w_err = ba_objective cams X w obs feat
////    printfn "%A" reproj_err
////    printfn "%A" f_prior_err
////    printfn "%A" w_err
//    let obj_stop_watch = Stopwatch.StartNew()
//    for i = 1 to nruns do    
//        ba.ba_objective cams X w obs feat
//    obj_stop_watch.Stop()
//    
//    let n = cams.Length
//    let m = X.Length
//    let p = obs.Length
//
////    let parameters = vectorize_in cams X w |> Array.map D
////    let err, J = jac_ba_objective parameters
////    printfn "%A" err
////    printfn "%A" J
//
////    let jac_stop_watch = Stopwatch.StartNew()
////    for i = 1 to nruns do
////        let camsD = cams |> Array.map (Array.map D)
////        let XD = X |> Array.map (Array.map D)
////        let wD = w |> Array.map D
////        ba_objective_ camsD XD wD obs feat
////    jac_stop_watch.Stop()
//    
//    let jac_stop_watch = Stopwatch.StartNew()
//    for i = 1 to nruns do
//        ba.ba_objective_ cams X w obs feat
//    jac_stop_watch.Stop()
//
//    let tf = ((float obj_stop_watch.ElapsedMilliseconds) / 1000.) / (float nruns)
//    let tJ = ((float jac_stop_watch.ElapsedMilliseconds) / 1000.) / (float nruns)
//    printfn "tf: %f" tf
//    printfn "tJ: %f" tJ
//    printfn "tJ/tf: %f" (tJ/tf)

#endif

[<EntryPoint>]
let main argv = 
    let dir_in = argv.[0]
    let dir_out = argv.[1]
    let fn = argv.[2]
    let nruns_f = (Int32.Parse argv.[3])
    let nruns_J = (Int32.Parse argv.[4])
    let replicate_point = 
        (argv.Length >= 6) && (argv.[5].CompareTo("-rep") = 0)

#if DO_GMM_FULL || DO_GMM_SPLIT
    test_gmm (dir_in + fn) (dir_out + fn) nruns_f nruns_J replicate_point
#endif

    0
