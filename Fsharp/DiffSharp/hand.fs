module hand

open System
open System.Diagnostics
open System.IO

#if MODE_AD
open DiffSharp.AD
open DiffSharp.AD.Vector
#endif
open FsAlg.Generic

type HandModel = {
    bone_names:string[]
    parents:int[]
    base_relatives:Matrix<float>[]
    inverse_base_absolutes:Matrix<float>[]
    base_positions:Matrix<float>
    weights:Matrix<float>
    is_mirrored:bool
}

type HandData = {
    model:HandModel
    correspondences:int[]
    points:Matrix<float>    
}

////// Objective //////

let to_pose_params (theta:_[]) n_bones =
  let n = 3 + n_bones
  let pose_params = Array2D.zeroCreate n 3
  for i=0 to 2 do
    pose_params.[0,i] <- theta.[i]
    pose_params.[1,i] <- 1.
    pose_params.[2,i] <- theta.[i + 3]

  let mutable i_theta = 6
  let pose_params_off = 4
  let n_fingers = 5
  for i=0 to n_fingers-1 do
    for j=1 to 3 do
      pose_params.[pose_params_off + i*4 + j,0] <- theta.[i_theta]
      i_theta <- i_theta+1
      if j=1 then
        pose_params.[pose_params_off + i*4 + j,1] <- theta.[i_theta]
        i_theta <- i_theta+1
  pose_params

let euler_angles_to_rotation_matrix (xzy:_[]) =
  let tx = xzy.[0]
  let ty = xzy.[2]
  let tz = xzy.[1]
  let Rx = matrix [[1.;0.;0.]; [0.; cos(tx);-sin(tx)];[ 0.; sin(tx); cos(tx)]]
  let Ry = matrix [[cos(ty); 0.; sin(ty)]; [0.; 1.; 0.]; [-sin(ty); 0.; cos(ty)]]
  let Rz = matrix [[cos(tz); -sin(tz); 0.]; [sin(tz); cos(tz); 0.]; [0.;0.;1.]]
  Rz*Ry*Rx

let get_posed_relatives (model:HandModel) (pose_params:_[,]) =
  let offset = 3
  let n_bones = model.bone_names.Length

  let make_relative (pose_params:_[]) (base_relative:Matrix<_>) =
    let R = euler_angles_to_rotation_matrix pose_params
    let T = Matrix.appendRow (Vector.create 4 0.) (Matrix.appendCol (Vector.create 3 0.) R)
    T.[3,3] <- 1.
    base_relative * T
  
  [|for i_bone=0 to n_bones-1 do yield (make_relative pose_params.[i_bone+offset,*] model.base_relatives.[i_bone])|]

let relatives_to_absolutes (relatives:Matrix<_>[]) (parents:int[]) =
  let absolutes = [|for i=0 to relatives.Length-1 do yield Matrix.identity 4|]
  for i=0 to parents.Length-1 do
    if parents.[i] = -1 then
      absolutes.[i] <- relatives.[i]
    else
      absolutes.[i] <- absolutes.[parents.[i]] * relatives.[i]
  absolutes

let angle_axis_to_rotation_matrix (angle_axis:_[]) =
  let n = sqrt (angle_axis |> Array.map (fun x -> x*x) |> Array.sum)
  if n < 0.0001 then
    Matrix.identity 3
  else
    let x = angle_axis.[0] / n
    let y = angle_axis.[1] / n
    let z = angle_axis.[2] / n

    let s = sin n
    let c = cos n
    
    matrix [[x*x + (1. - x*x)*c; x*y*(1. - c) - z*s; x*z*(1. - c) + y*s]; 
                  [x*y*(1. - c) + z*s; y*y + (1. - y*y)*c; y*z*(1. - c) - x*s];
                  [x*z*(1. - c) - y*s; z*y*(1. - c) + x*s; z*z + (1. - z*z)*c]]

let apply_global_transform (pose_params:_[,]) (positions:Matrix<_>) = 
  let R = angle_axis_to_rotation_matrix pose_params.[0,*]
  let scale = Matrix.ofArray 1 pose_params.[1,*] // 1 row vector
  for i=0 to 2 do
    Matrix.replaceWith R.[i,*] ((Matrix.row i R) .* scale)
  
  let T = Matrix.appendCol (Vector.ofArray pose_params.[2,*]) R
  
  let positions_homog = Matrix.appendRow (Vector.create positions.Cols 1.) positions
  T * positions_homog

let get_skinned_vertex_positions (model:HandModel) (pose_params:_[,]) =
  let relatives = get_posed_relatives model pose_params
  let absolutes = relatives_to_absolutes relatives model.parents
  
  let transforms = Array.map2 (*) absolutes model.inverse_base_absolutes
  
  let n_verts = model.base_positions.Cols
  let positions = Matrix.create 3 n_verts 0.
  for i_transform=0 to transforms.Length-1 do
    let curr_positions = transforms.[i_transform].[0..2,*] * model.base_positions
    Matrix.replacei2 (fun i j pos curr_pos -> pos + curr_pos * model.weights.[i_transform,j]) positions curr_positions

  if model.is_mirrored then
    for i=0 to positions.Cols do
      positions.[0,i] <- -positions.[0,i]
    
  let apply_global = true
  if apply_global then
    apply_global_transform pose_params positions
  else
    positions

let hand_objective (param:_[]) (data:HandData) =
  let pose_params = to_pose_params param data.model.bone_names.Length
  
  let vertex_positions = get_skinned_vertex_positions data.model pose_params
  
  let n_corr = data.correspondences.Length
  let err = [|for i=0 to n_corr-1 do yield Matrix.toArray (data.points.[*,i] - vertex_positions.[*,data.correspondences.[i]])|]
  [|for elems in err do for elem in elems do yield elem|]
  
////// IO //////

let read_hand_instance (model_dir:string) (fn_in:string) =
    let read_in_elements (fn:string) (separators:_[]) =
        let string_lines = File.ReadLines(fn)
        [| for line in string_lines do yield line.Split separators |] 
            |> Array.map (Array.filter (fun x -> x.Length > 0))

    let bones_name = model_dir + "bones.txt"
    let lines = array2D (read_in_elements bones_name [|':'|])

    let bone_names = lines.[*,0]
    let n_bones = bone_names.Length

    let parents = lines.[*,1] |> Array.map Int32.Parse

    let reshape (entries:_[]) d1 d2 = 
        array2D [|for i=0 to d1-1 do
                    yield [|for j=0 to d2-1 do
                                yield entries.[i*d2 + j] |] |]
            
    let transforms = 
        [|for i=0 to n_bones-1 do 
            yield reshape (Array.map Double.Parse lines.[i,2..17]) 4 4|]

    let inverse_absolute_transforms = 
        [|for i=0 to n_bones-1 do 
            yield reshape (Array.map Double.Parse lines.[i,18..33]) 4 4|]
            
    let vetices_name = model_dir + "vertices.txt"
    let data = read_in_elements vetices_name [|':'|]
    let n_verts = data.Length

    let base_positions =
        array2D ([|for i=0 to n_verts-1 do
                    yield (Array.map Double.Parse data.[i].[0..2])|])
    
    let get_weights sz (x:String[]) = 
        let out = Array.zeroCreate sz
        let n = Int32.Parse x.[0]
        for i=0 to n-1 do
            let idx = Int32.Parse x.[2*i + 1]
            out.[idx] <- Double.Parse x.[2*i + 2]
        out        

    let weights = 
        array2D ([|for i=0 to n_verts-1 do
                    yield (get_weights n_bones data.[i].[8..])|])

    let base_positions_ = Matrix.transpose (Matrix.ofArray2D base_positions)
    let base_positions_homog = Matrix.appendRow (Vector.create n_verts 1.) base_positions_
    let model = {
        bone_names = bone_names;
        parents = parents;
        base_relatives = Array.map Matrix.ofArray2D transforms;
        inverse_base_absolutes = Array.map Matrix.ofArray2D inverse_absolute_transforms;
        base_positions = base_positions_homog;
        weights = Matrix.transpose (Matrix.ofArray2D weights);
        is_mirrored = false
        }

    let instance = read_in_elements fn_in  [|' '|]

    let n_pts = Int32.Parse instance.[0].[0]
    let n_params = Int32.Parse instance.[0].[1]
    let mutable offset = 1

    let correspondences = [|for i=0 to n_pts-1 do yield (Int32.Parse instance.[offset+i].[0])|]
    let pts = array2D [|for i=0 to n_pts-1 do
                        yield (Array.map Double.Parse instance.[offset+i].[1..])|]
    offset <- offset + n_pts

    let param = [|for i=0 to n_params-1 do yield (Double.Parse instance.[offset+i].[0])|]

    let points_mat = Matrix.ofArray2D pts
    let data = {
        model=model;
        correspondences=correspondences;
        points=points_mat.GetTranspose()
        }

    param, data