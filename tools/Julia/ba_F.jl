# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

using ForwardDiff
using Printf
using LinearAlgebra

const Vec = Vector{Float64}
const Mat = Matrix{Float64}
const iMat = Matrix{Int}

N_CAM_PARAMS = 11
ROT_IDX = 1
C_IDX = 4
F_IDX = 7
X0_IDX = 8
RAD_IDX = 10

##################### objective #############################

function rodrigues_rotate_point(rot :: Vector{T}, X :: Vector{T}) where T
  sqtheta = sum(rot.*rot)
  if sqtheta > 1e-10
    theta = sqrt(sqtheta)
    costheta = cos(theta)
    sintheta = sin(theta)
    theta_inverse = 1. / theta

    w = theta_inverse * rot
    w_cross_X = cross(w,X)
    tmp = dot(w,X) * (1. - costheta)

    X*costheta + w_cross_X * sintheta + w * tmp
  else
    X + cross(rot,X)
  end
end

function radial_distort(rad_params,proj)
  rsq = sum(proj.*proj)
  L = 1. + rad_params[1]*rsq + rad_params[2]*rsq*rsq
  proj*L
end

function project(cam,X)
  Xcam = rodrigues_rotate_point(cam[ROT_IDX:ROT_IDX+2], X - cam[C_IDX:C_IDX+2])
  distorted = radial_distort(cam[RAD_IDX:RAD_IDX+1], Xcam[1:2]/Xcam[3])
  distorted*cam[F_IDX] + cam[X0_IDX:X0_IDX+1]
end

function compute_reproj_err(cam,X,w,feat)
  return w*(project(cam,X) - feat)
end

function ba_objective(cams,X,w,obs,feats)
  reproj_err = similar(feats)
  for i in 1:size(feats,2)
    reproj_err[:,i] = compute_reproj_err(cams[:,obs[1,i]],X[:,obs[2,i]],w[i],feats[:,i])
  end
  w_err = 1.0 .- w.*w
  (reproj_err, w_err)
end

#################### derivatives extra ##########################

function pack(cam,X,w)
  [cam[:];X[:];w]
end

function unpack(packed)
  packed[1:end-4],packed[end-3:end-1],packed[end]
end

function compute_w_err(w)
    1.0 - w*w
end
compute_w_err_d = x -> ForwardDiff.derivative(compute_w_err, x)

function compute_reproj_err_d(params, feat)
  cam, X, w = unpack(params)
  compute_reproj_err(cam,X,w,feat)
end

function compute_ba_J(cams,X,w,obs,feats)
  p = size(obs,2)
  reproj_err_d = zeros(2*p, N_CAM_PARAMS + 3 + 1)
  for i in 1:p
    compute_reproj_err_d_i = x -> compute_reproj_err_d(x, feats[:,i])
    idx = (2*(i-1))+1
    reproj_err_d[idx:idx+1,:] = ForwardDiff.jacobian(compute_reproj_err_d_i,
              pack(cams[:,obs[1,i]],X[:,obs[2,i]],w[i]))
  end
  w_err_d = zeros(1,p)
  for i in 1:p
    w_err_d[i] = compute_w_err_d(w[i])
  end
  (reproj_err_d, w_err_d)
end

# precompile as much as possible
precompile(rodrigues_rotate_point,(Vec,Vec))
precompile(radial_distort,(Vec,Vec))
precompile(project,(Vec,Vec))
precompile(compute_reproj_err,(Vec,Vec,Float64,Vec))
precompile(ba_objective,(Mat,Mat,Vec,iMat,Mat))

precompile(compute_ba_J,(Mat,Mat,Vec,iMat,Mat))
precompile(compute_reproj_err_d,(Vec,Vec))
precompile(compute_w_err_d,(Vec,))

#################### IO ############################
function read_ba_instance(fn)
  fid = open(fn)
  lines = readlines(fid)
  close(fid)
  line=split(lines[1]," ")
  n = parse(Int,line[1])
  m = parse(Int,line[2])
  p = parse(Int,line[3])
  off = 2

  one_cam = zeros(Float64,N_CAM_PARAMS,1)
  line=split(lines[off]," ")
  for i in 1:N_CAM_PARAMS
    one_cam[i] = parse(Float64,line[i])
  end
  cams = repeat(one_cam,1,n)
  off += 1

  one_X = zeros(Float64,3,1)
  line=split(lines[off]," ")
  for i in 1:3
    one_X[i] = parse(Float64,line[i])
  end
  X = repeat(one_X,1,m)
  off += 1

  one_w = parse(Float64,lines[off])
  w = repeat([one_w],1,p)
  off += 1

  one_feat = zeros(Float64,2,1)
  line=split(lines[off]," ")
  for i in 1:2
    one_feat[i] = parse(Float64,line[i])
  end
  feats = repeat(one_feat,1,p)

  camIdx = 1
  ptIdx = 1
  obs = zeros(Int,2,p)
  for i in 1:p
    obs[1,i] = camIdx
    obs[2,i] = ptIdx
    camIdx = (camIdx%n) + 1
    ptIdx = (ptIdx%m) + 1
  end

  (cams,X,w,obs,feats)
end

function write_times(fn,tf,tJ)
  @printf "Writing to %s\n" fn
  fid = open(fn,"w")
  @printf fid "%f %f\r\n" tf tJ
  @printf fid "tf tJ\r\n"
  close(fid)
end

##################### run it ###########################

# Read instance
function main(ARGS)
  dir_in = ARGS[1]
  dir_out = ARGS[2]
  fn = ARGS[3]
  nruns_f = parse(Int,ARGS[4])
  nruns_J = parse(Int,ARGS[5])

  fn_in = string(dir_in, fn)
  fn_out = string(dir_out, fn)

  cams,X,w,obs,feats = read_ba_instance(string(fn_in,".txt"))

  # compute once for precompilation
  reproj_err, w_err = ba_objective(cams,X,w,obs,feats)
  # Time runs
  tf = @elapsed for i in 1:nruns_f
    reproj_err, w_err = ba_objective(cams,X,w,obs,feats)
  end
  tf /= nruns_f
  @printf "tf: %g\n" tf
  #println(reproj_err)
  #println(w_err)

  # compute once for precompilation
  J = compute_ba_J(cams,X,w,obs,feats)
  # Time runs
  tJ = @elapsed for i in 1:nruns_J
    J = compute_ba_J(cams,X,w,obs,feats)
  end
  tJ /= nruns_J; 
  @printf "tJ: %g\n" tJ
  #println("J:")
  #println(J)

  name = "Julia"

  #write_J(string(fn_out,"_J_",name,".txt"),J)
  write_times(string(fn_out,"_times_",name,".txt"),tf,tJ)
end

if isinteractive()
  main([raw"C:\dev\github\autodiff/data/ba/", raw"C:\dev\github\autodiff/tmp/Release/ba/Julia/", "ba1", "1", "1", "60"])
else
  main(ARGS)
end
