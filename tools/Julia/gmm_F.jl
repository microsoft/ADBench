# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#Pkg.add("ForwardDiff")
#Pkg.add("SpecialFunctions")
#Pkg.update()
#Pkg.checkout("ForwardDiff")
#Pkg.status()
using Printf
using SpecialFunctions
using ForwardDiff

include("common.jl")

# input should be 1 dimensional
function logsumexp(x)
  mx = maximum(x)
  log.(sum(exp.(x .- mx))) .+ mx
end

@inbounds function gmm_objective(alphas,means,icf,x,wishart::Wishart)
  d = size(x,1)
  n = size(x,2)
  CONSTANT = -n*d*0.5*log(2 * pi)

  sum_qs = sum(icf[1:d,:],dims=1)
  slse = sum(sum_qs)
  Qs = [get_Q(d,icf[:,ik]) for ik in 1:k]
  main_term = zeros(eltype(alphas),1,k)

  slse = 0.
  for ix=1:n
    for ik=1:k
      main_term[ik] = -0.5*sum(abs2, Qs[ik] * (x[:,ix] - means[:,ik]))
    end
    slse += logsumexp(alphas + sum_qs + main_term)
  end

  CONSTANT + slse - n*logsumexp(alphas) + log_wishart_prior(wishart, sum_qs, Qs, icf)
end

# Read instance
if length(ARGS) < 5
  throw("Too few args")
end

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
# Call once in case of precompilation etc
err = gmm_objective(alphas,means,icf,x,wishart)

tf = @elapsed for i in 1:nruns_f
  gmm_objective(alphas,means,icf,x,wishart)
end
tf = tf/nruns_f;
@printf "tf: %g\n" tf
#@printf "err: %f\n" err

# Gradient helper
function wrapper_gmm_objective(packed)
  alphas,means,icf = unpack(d,k,packed)
  gmm_objective(alphas,means,icf,x,wishart)
end

# Gradient
g = x-> ForwardDiff.gradient(wrapper_gmm_objective, x)

J = g(pack(alphas,means,icf))

tJ = @elapsed for i in 1:nruns_J
  g(pack(alphas,means,icf))
end
tJ = tJ/nruns_J;
@printf "tJ: %g\n" tJ
#println("J:")
#println(J)

name = "Julia"

write_J(string(fn_out,"_J_",name,".txt"),J)
write_times(string(fn_out,"_times_",name,".txt"),tf,tJ)

