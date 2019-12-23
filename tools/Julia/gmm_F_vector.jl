# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#Pkg.add("ForwardDiff")
#Pkg.update()
#Pkg.checkout("ForwardDiff")
#Pkg.status()
using ForwardDiff

include("common.jl")

# matrix version which works with ForwardDiff
function logsumexp_AD_mat(X)
  n = size(X,2)
  mX = [maximum(X[:,i]) for i in 1:n]
  log(sum(exp(X .- mX'),1)) + mX'
end
# input should be 1 dimensional
function logsumexp_AD_vec(x)
  mx = maximum(x)
  log(sum(exp(x - mx))) + mx
end

@inbounds function gmm_objective_AD(alphas,means,icf,x,wishart::Wishart)
  d = size(x,1)
  n = size(x,2)
  CONSTANT = -n*d*0.5*log(2 * pi)

  sum_qs = sum(icf[1:d,:],1)
  slse = sum(sum_qs)
  Qs = [get_Q(d,icf[:,ik]) for ik in 1:k]
  main_term = zeros(eltype(alphas),k,n)

  for ik=1:k
    Qxcentered = Qs[ik] * (x .- means[:,ik])
    main_term[ik,:] = alphas[ik] + sum_qs[ik] - 0.5*sumabs2(Qxcentered,1)
  end

  CONSTANT + sum(logsumexp_AD_mat(main_term)) - n*logsumexp_AD_vec(alphas) + log_wishart_prior(wishart, sum_qs, Qs, icf)
end

function logsumexp(X,axis=2)
  mX = maximum(X,axis)
  log(sum(exp(X .- mX),axis)) + mX
end
typealias Mat Matrix{Float64}

@inbounds function gmm_objective(alphas::Mat,means::Mat,icf::Mat,x::Mat,wishart::Wishart)
  d = size(x,1)
  n = size(x,2)
  CONSTANT = -n*d*0.5*log(2 * pi)

  sum_qs = sum(icf[1:d,:],1)
  slse = sum(sum_qs)
  Qs = [get_Q(d,icf[:,ik]) for ik in 1:k]
  main_term = zeros(eltype(alphas),k,n)

  for ik=1:k
    Qxcentered = Qs[ik] * (x .- means[:,ik])
    main_term[ik,:] = alphas[ik] + sum_qs[ik] - 0.5*sumabs2(Qxcentered,1)
  end

  lse_alphas = n*logsumexp(alphas);
  CONSTANT + sum(logsumexp(main_term,1)) - lse_alphas[1] + log_wishart_prior(wishart, sum_qs, Qs, icf)
end

# Read instance
#dir_in = "C:\\Users\\t-filsra\\Workspace\\autodiff\\"
#dir_out = "C:\\Users\\t-filsra\\Workspace\\autodiff\\"
#fn = "gmm"
dir_in = ARGS[1]
dir_out = ARGS[2]
fn = ARGS[3]
nruns_f = parse(Int,ARGS[4])
nruns_J = parse(Int,ARGS[5])
replicate_point = size(ARGS,1) >= 6 && ARGS[6] == "-rep"

fn_in = string(dir_in, fn)
fn_out = string(dir_out, fn)

alphas,means,icf,x,wishart = read_gmm_instance(string(fn_in,".txt"),replicate_point)
d = size(means,1)
k = size(means,2)
n = size(x,2)

# Objective
precompile(gmm_objective,(typeof(alphas),typeof(means),typeof(icf),typeof(x),Wishart))
err = 0.
tic()
for i in 1:nruns_f
  err = gmm_objective(alphas,means,icf,x,wishart)
end
tf = toq()/nruns_f
@printf "tf: %g\n" tf
#println(err)


# Gradient helper
function wrapper_gmm_objective_AD(packed)
  alphas,means,icf = unpack(d,k,packed)
  gmm_objective_AD(alphas,means,icf,x,wishart)
end

# Gradient
g = ForwardDiff.gradient(wrapper_gmm_objective_AD)
precompile(pack,(typeof(alphas),typeof(means),typeof(icf)))
precompile(g,(typeof(alphas),typeof(means),typeof(icf)))
J = zeros(1,length(alphas)+length(means)+length(icf))
tic()
for i in 1:nruns_J
  J = g(pack(alphas,means,icf))
end
tJ = toq()/nruns_J
@printf "tJ: %g\n" tJ
#println("J:")
#println(J)

name = "Julia_F_vector"

write_J(string(fn_out,"_J_",name,".txt"),J)
write_times(string(fn_out,"_times_",name,".txt"),tf,tJ)

