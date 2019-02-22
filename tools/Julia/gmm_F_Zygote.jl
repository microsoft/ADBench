#using Pkg
#Pkg.add("ForwardDiff")
#Pkg.add("SpecialFunctions")
#Pkg.update()
#Pkg.checkout("ForwardDiff")
#Pkg.status()
using Printf
using SpecialFunctions
using ForwardDiff
using Zygote
using Zygote: @adjoint
using LinearAlgebra

include("common.jl")

# input should be 1 dimensional
function logsumexp(x)
  mx = maximum(x)
  log(sum(exp.(x .- mx))) + mx
end

# function diagsum(m)
#     s = 0.
#     for i in 1:size(m,1)
#         s += m[i,i]
#     end
#     s
# end

function diagsums(Qs)
  mapslices(slice -> sum(diag(slice)), Qs; dims=[1,2])
end

@adjoint function diagsums(Qs)
  diagsums(Qs),
  function (Δ)
      Δ′ = zero(Qs)
      for (i, δ) in enumerate(Δ)
          d = size(Qs, 1)
          for j in 1:d
              Δ′[j,j,i] = δ
          end
      end
      (Δ′,)
  end
end

function expdiags(Qs)
  mapslices(Qs; dims=[1,2]) do slice
    slice[diagind(slice)] .= exp.(slice[diagind(slice)])
    slice
  end
end

@adjoint function expdiags(Qs)
  expdiags(Qs),
  function (Δ)
      Δ′ = zero(Qs)
      Δ′ .= Δ
      k = size(Qs, 3)
      for i in 1:k
          d = size(Qs, 1)
          for j in 1:d
              Δ′[j,j,i] *= exp(Qs[j,j,i])
          end
      end
      (Δ′,)
  end
end

@adjoint function map(f, args...)
    map(f, args...), function (Δ)
      @show "aaaaaaaaaaaaaaaaaaargs", args
      Δargs_tuples = Zygote.gradient.(f, args...)
      @show Δargs_tuples
      Δargs = map(i-> Δ.*getindex.(Δargs_tuples, i), 1:length(args))
      (nothing, Δargs...)
    end
end

function main_terms(Qs, x, means, ix)
  formula(ik) = -0.5*sum(abs2, Qs[:, :, ik] * (x[:,ix] - means[:,ik]))
  map(formula, 1:k)
end

@adjoint function main_terms(Qs, x, means, ix)
  main_terms(Qs, x, means, ix),
  function (Δ)
    ΔQ = zero(Qs)
    Δx = zero(x)
    Δmeans = zero(means)
    Δix = nothing
    k = size(Qs, 3)
    for (ik, δ) in enumerate(Δ)
      formula(Qs, x, means) = -0.5*sum(abs2, Qs[:, :, ik] * (x[:,ix] .- means[:,ik]))
      (ΔQ, Δx, Δmeans) = (ΔQ, Δx, Δmeans) .+ δ .* Zygote.gradient(formula, Qs, x, means)
    end
    (ΔQ, Δx, Δmeans, Δix)
  end
end

Base.:*(::Float64, ::Nothing) = nothing

function gmm_objective(alphas,means,Qs,x,wishart::Wishart)
  d = size(x,1)
  n = size(x,2)
  CONSTANT = -n*d*0.5*log(2 * pi)
  # @show CONSTANT
  # sum_qs = sum(icf[1:d,:],dims=1)
  sum_qs = reshape(diagsums(Qs), 1, size(Qs, 3))
  slse = sum(sum_qs)
  # @show size(sum_qs), typeof(sum_qs)
  # @show "before", Qs
  Qs = expdiags(Qs)
  # @show "after", Qs
  # get_Q(d,icf[:,1])
  # Qs = [get_Q(d,icf[:,ik]) for ik in 1:k]
  # FIX WITH: broadcast over getindex
  # @show Qs
  # @show d
  # @show n
  # @show icf
  # @show size(alphas)
  # @show size(means)

  main_term = zeros(Float64,1,k)

  slse = 0.
  for ix=1:n
    main_term = main_terms(Qs, x, means, ix)
    slse += logsumexp(alphas + sum_qs + reshape(main_term, 1, k))
  end

  CONSTANT + slse - n*logsumexp(alphas) # + log_wishart_prior_zygote(wishart, sum_qs, Qs, icf)
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

alphas,means,icf,x,wishart = read_gmm_instance(string(fn_in,".txt"),replicate_point)  # Tuple{Array{Float64,2},Array{Float64,2},Array{Float64,2},Array{Float64,2},Wishart}
@show typeof((alphas,means,icf,x,wishart))
const d = size(means,1)
const k = size(means,2)
# n = size(x,2)
const Qs = cat([get_Q_zygote(d,icf[:,ik]) for ik in 1:k]...; dims=[3])
const sum_qs = sum(icf[1:d,:],dims=1)
@show "outside", size(sum_qs), typeof(sum_qs), sum_qs, Qs

# Objective
# Call once in case of precompilation etc
err = gmm_objective(alphas,means,Qs,x,wishart)

tf = @elapsed for i in 1:nruns_f
  gmm_objective(alphas,means,Qs,x,wishart)
end
tf = tf/nruns_f;
@printf "tf: %g\n" tf
#@printf "err: %f\n" err

# Gradient helper
# Use to avoid unnecessary calculation of gradient of x.
function wrapper_gmm_objective(alphas, means, Qs)
  # @show typeof(packed)
  # alphas,means,icf = unpack(d,k,packed)
  gmm_objective(alphas,means,Qs,x,wishart)
end

# Gradient
g = (alphas, means, Qs)-> Zygote.gradient(wrapper_gmm_objective, alphas, means, Qs)

# vars = pack(alphas,means,icf)
J = g(alphas, means, Qs)
@show J, typeof(J)
packed_J = J[1]
@show packed_J

# tJ = @elapsed for i in 1:nruns_J
#   g(pack(alphas,means,icf))
# end
# tJ = tJ/nruns_J;
# @printf "tJ: %g\n" tJ
#println("J:")
#println(J)

name = "Julia"

# write_J(string(fn_out,"_J_",name,".txt"), packed_J)
# write_times(string(fn_out,"_times_",name,".txt"),tf,tJ)