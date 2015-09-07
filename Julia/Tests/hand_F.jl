#Pkg.add("ForwardDiff")
#Pkg.update()
#Pkg.checkout("ForwardDiff")
#Pkg.status()
using ForwardDiff

include("common_io.jl")

typealias iVec Vector{Int}
typealias Vec Vector{Float64}
typealias Mat Matrix{Float64}
typealias Tensor3 Array{Float64,3}

type HandModel
  bone_names::Vector{String}
  parents::iVec
  base_relatives::Tensor3
  inverse_base_absolutes::Tensor3
  base_positions::Mat
  weights::Mat
  is_mirrored::Bool
end

type HandData
  model::HandModel
  correspondences::iVec
  points::Mat
end

#################### IO ############################
function read_hand_instance(path)
  bones_fn = joinpath(path,"bones.txt");

  A = readdlm(bones_fn, ':')

  n_bones = size(A,1)
  bone_names = A[:,1]
  parents = A[:,2] + 1 #julia indexing

  transforms = A[:,3:18]
  transforms = permutedims(reshape(transforms,(n_bones,4,4)), (1,3,2))

  inverse_absolute_transforms  = A[:,19:34]
  inverse_absolute_transforms = permutedims(reshape(
    inverse_absolute_transforms,(n_bones,4,4)),(1,3,2));

  vertices_fn = joinpath(path,"vertices.txt")
  A = readdlm(vertices_fn,':');

  base_positions = A[:,1:3]';
  n_vertices = size(A,1);

  weights = zeros(Float64,n_bones,n_vertices);
  for i_vert = 1:n_vertices
      for i=0:A[i_vert,9]-1
        i_bone = A[i_vert,9 + i*2 + 1] + 1; #julia indexing
        weights[i_bone, i_vert] = A[i_vert,9 + i*2 + 2];
      end
  end

  model = HandModel(bone_names,parents,transforms,
                    inverse_absolute_transforms,
                    [base_positions; ones(Float64,1,size(base_positions,2))],
                    weights,false)

  fid = open(joinpath(path,"instance.txt"))
  lines = readlines(fid)
  close(fid)
  line=split(lines[1]," ")
  n_corrs = parse(Int,line[1])
  n_params = parse(Int,line[2])
  off = 1

  corrs = zeros(Int,n_corrs)
  pts = zeros(Float64,3,n_corrs)
  for i in 1:n_corrs
    line=split(lines[i+off]," ")
    corrs[i] = parse(Int,line[1]) + 1 #julia indexing
    for j in 1:3
      pts[j,i] = parse(Float64,line[j+1])
    end
  end
  off += n_corrs

  params = zeros(Float64,n_params)
  for i in 1:n_params
    params[i] = parse(Float64,lines[i+off])
  end

  data = HandData(model, corrs, pts)

  (params, data)
end

##################### objective #############################

function euler_angles_to_rotation_matrix(xyz)
  tx = xyz[1]
  ty = xyz[2]
  tz = xyz[3]
  Rx = [1 0 0; 0  cos(tx) -sin(tx); 0 sin(tx) cos(tx)]
  Ry = [cos(ty) 0 sin(ty); 0 1 0; -sin(ty) 0 cos(ty)]
  Rz = [cos(tz) -sin(tz) 0; sin(tz) cos(tz) 0; 0 0 1]
  return Rz*Ry*Rx;
end

function get_posed_relatives(model, pose_params)
# default parametrization xzy # Flexion, Abduction, Twist
  order = [1, 3, 2]
  offset = 3
  n_bones = size(model.bone_names,1)
  relatives = zeros(eltype(pose_params),n_bones,4,4)

  for i_bone = 1:n_bones
    T = eye(eltype(pose_params),4)
    T[1:3,1:3] = euler_angles_to_rotation_matrix(pose_params[order,i_bone+offset])
    relatives[i_bone,:,:] = squeeze(model.base_relatives[i_bone,:,:],1) * T
  end
  relatives
end

function relatives_to_absolutes(relatives, parents)
  absolutes = zeros(eltype(relatives),size(relatives));
  for i=1:length(parents)
    if parents[i] == 0
      absolutes[i,:,:] = relatives[i,:,:]
    else
      absolutes[i,:,:] = squeeze(absolutes[parents[i],:,:],1) *
               squeeze(relatives[i,:,:],1)
    end
  end
  absolutes
end

function angle_axis_to_rotation_matrix(angle_axis)
  n = sqrt(sum(angle_axis.^2));
  if n < .0001
      return eye(eltype(angle_axis),3)
  end

  x = angle_axis[1] / n
  y = angle_axis[2] / n
  z = angle_axis[3] / n

  s = sin(n)
  c = cos(n)

  R = [x*x+(1-x*x)*c x*y*(1-c)-z*s x*z*(1-c)+y*s;
    x*y*(1-c)+z*s y*y+(1-y*y)*c y*z*(1-c)-x*s;
    x*z*(1-c)-y*s z*y*(1-c)+x*s z*z+(1-z*z)*c]
  return R
end

function apply_global_transform(pose_params, positions)
  T = eye(eltype(pose_params),3,4)
  T[:,1:3] = angle_axis_to_rotation_matrix(pose_params[:,1]);
  T[:,1:3] = T[1:3,1:3] .* pose_params[:,2]'
  T[:,4] = pose_params[:,3]

  return T * [positions; ones(eltype(positions),1,size(positions,2))]
end

function get_skinned_vertex_positions(model, pose_params)
  relatives = get_posed_relatives(model, pose_params)

  absolutes = relatives_to_absolutes(relatives, model.parents)

  transforms = zeros(eltype(pose_params),size(absolutes))
  for i=1:size(transforms,1)
    transforms[i,:,:] = squeeze(absolutes[i,:,:],1) *
        squeeze(model.inverse_base_absolutes[i,:,:],1)
  end

  n_verts = size(model.base_positions,2)
  positions = zeros(eltype(transforms),3,n_verts)
  for i=1:size(transforms,1)
    positions = positions +
        (squeeze(transforms[i,1:3,:],1) * model.base_positions) .* model.weights[i,:]
  end

  if model.is_mirrored
    positions[1,:] = -positions[1,:]
  end

  apply_global = true
  if apply_global
    positions = apply_global_transform(pose_params, positions)
  end
  positions
end

function to_pose_params(theta,n_bones)
# to_pose_params !!!!!!!!!!!!!!! fixed order pose_params !!!!!
#       1) global_rotation 2) scale 3) global_translation
#       4) wrist
#       5) thumb1, 6)thumb2, 7) thumb3, 8) thumb4
#       similarly: index, middle, ring, pinky
#       end) forearm

  n = 3 + n_bones
  pose_params = zeros(eltype(theta),3,n)

  pose_params[:,1] = theta[1:3]
  pose_params[:,2] = 1
  pose_params[:,3] = theta[4:6]

  i_theta = 7
  i_pose_params = 6
  n_fingers = 5
  for finger = 1:n_fingers
    for i=2:4
      pose_params[1,i_pose_params] = theta[i_theta]
      i_theta = i_theta + 1
      if i==2
        pose_params[2,i_pose_params] = theta[i_theta]
        i_theta = i_theta + 1
      end
      i_pose_params = i_pose_params+1
    end
    i_pose_params = i_pose_params+1
  end
  pose_params
end

function hand_objective(params, data)
  pose_params = to_pose_params(params, length(data.model.bone_names))

  vertex_positions = get_skinned_vertex_positions(data.model, pose_params)

  n_corr = length(data.correspondences)
  err = zeros(eltype(params),3, n_corr)
  for i=1:n_corr
      err[:,i] = data.points[:,i] - vertex_positions[:,data.correspondences[i]]
  end
  err
end

##################### run it ###########################

# Read instance
dir_in = ARGS[1]
dir_out = ARGS[2]
fn = ARGS[3]
nruns_f = parse(Int,ARGS[4])
nruns_J = parse(Int,ARGS[5])

path = joinpath(dir_in, fn)
fn_out = string(dir_out, fn)

params,data = read_hand_instance(path)

precompile(euler_angles_to_rotation_matrix,(Vec,))
precompile(get_posed_relatives,(HandModel, Mat))
precompile(relatives_to_absolutes,(Tensor3, iVec))
precompile(angle_axis_to_rotation_matrix,(Vec,))
precompile(apply_global_transform,(Mat, Mat))
precompile(get_skinned_vertex_positions,(HandModel, Mat))
precompile(to_pose_params,(Vec, Int))

err = zeros(Float64,3,size(data.points,2))
tic()
for i in 1:nruns_f
  err = hand_objective(params, data)
end
tf = toq()/nruns_f;
@printf "tf: %g\n" tf
#println(err)

# Gradient helper
function wrapper_hand_objective(params)
  err=hand_objective(params,data)
  err[:]
end

# Gradient
g = jacobian(wrapper_hand_objective)
precompile(g,(Vec,))
J = zeros(3*size(data.points,2),length(params))
tic()
for i in 1:nruns_J
  J = g(params)
end
tJ = toq()/nruns_J;
@printf "tJ: %g\n" tJ
#println("J:")
#println(J)

name = "Julia_F"

write_J(string(fn_out,"_J_",name,".txt"),J)
write_times(string(fn_out,"_times_",name,".txt"),tf,tJ)
