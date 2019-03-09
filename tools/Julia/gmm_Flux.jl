#using Pkg
#Pkg.add("ForwardDiff")
#Pkg.add("SpecialFunctions")
#Pkg.update()
#Pkg.checkout("ForwardDiff")
#Pkg.status()
using Printf
using SpecialFunctions
using Flux
using LinearAlgebra
using Flux.Tracker: TrackedArray, track, @grad, data

include("common.jl")

# input should be 1 dimensional
function logsumexp(x)
  mx = maximum(x)
  log(sum(exp.(x .- mx))) + mx
end

function diagsums(Qs)
  mapslices(slice -> sum(diag(slice)), Qs; dims=[1,2])
end

# @grad function diagsums(Qs)
#   diagsums(Qs),
#   function (Δ)
#       Δ′ = zero(Qs)
#       for (i, δ) in enumerate(Δ)
#           for j in 1:size(Qs, 1)
#               Δ′[j,j,i] = δ
#           end
#       end
#       (Δ′,)
#   end
# end

expdiags(Qs::TrackedArray) = track(expdiags, Qs)
function expdiags(Qs)
  mapslices(Qs; dims=[1,2]) do slice
    slice[diagind(slice)] .= exp.(slice[diagind(slice)])
    slice
  end
end

@grad function expdiags(Qs)
  dQs = data(Qs)
  expdiags(dQs),
  function (Δ)
      Δ′ = zero(dQs)
      Δ′ .= Δ
      for i in 1:size(dQs, 3)
          for j in 1:size(dQs, 1)
              Δ′[j,j,i] *= exp(dQs[j,j,i])
          end
      end
      (Δ′,)
  end
end

# function unzip(tuples)
#   map(1:length(first(tuples))) do i
#       map(tuple -> tuple[i], tuples)
#   end
# end
# @grad function map(f, args...)
#   ys_and_backs = map((args...) -> Zygote._forward(__context__, f, args...), args...)
#   ys, backs = unzip(ys_and_backs)
#   ys, function (Δ)
#     Δf_and_args_zipped = map((f, δ) -> f(δ), backs, Δ)
#     Δf_and_args = unzip(Δf_and_args_zipped)
#     Δf = reduce(Zygote.accum, Δf_and_args[1])
#     (Δf, Δf_and_args[2:end]...)
#   end
# end

# @grad function main_terms(Qs, x, means, ix)
#   main_terms(Qs, x, means, ix),
#   function (Δ)
#     ΔQ = zero(Qs)
#     Δx = zero(x)
#     Δmeans = zero(means)
#     Δix = nothing
#     k = size(Qs, 3)
#     for (ik, δ) in enumerate(Δ)
#       formula(Qs, x, means) = -0.5*sum(abs2, Qs[:, :, ik] * (x[:,ix] .- means[:,ik]))
#       (ΔQ, Δx, Δmeans) = (ΔQ, Δx, Δmeans) .+ δ .* Zygote.gradient(formula, Qs, x, means)
#     end
#     (ΔQ, Δx, Δmeans, Δix)
#   end
# end

Base.:*(::Float64, ::Nothing) = nothing

function gmm_objective(alphas,means,Qs,x,wishart::Wishart)
  d = size(x,1)
  n = size(x,2)
  CONSTANT = -n*d*0.5*log(2 * pi)
  sum_qs = reshape(diagsums(Qs), 1, size(Qs, 3))
  slse = sum(sum_qs)
  Qs = expdiags(Qs)

  main_term = zeros(Float64,1,k)

  slse = 0.
  for ix=1:n
    formula(ik) = -0.5*sum(abs2, Qs[:, :, ik] * (x[:,ix] .- means[:,ik]))
    sumexp = 0.
    for ik=1:k
      sumexp += exp(formula(ik) + alphas[ik] + sum_qs[ik])
    end
    slse += log(sumexp)
  end

  CONSTANT + slse - n*logsumexp(alphas) + log_wishart_prior_zygote(wishart, sum_qs, Qs)
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
const d = size(means,1)
const k = size(means,2)
const Qs = cat([get_Q_zygote(d,icf[:,ik]) for ik in 1:k]...; dims=[3])

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
  gmm_objective(alphas,means,Qs,x,wishart)
end

# Gradient
g = (alphas, means, Qs)-> Flux.gradient(wrapper_gmm_objective, alphas, means, Qs)

J = g(alphas, means, Qs)

tJ = @elapsed for i in 1:nruns_J
  g(alphas, means, Qs)
end
tJ = tJ/nruns_J;
@printf "tJ: %g\n" tJ
println("J:")
println(J)

name = "Julia_Flux"

function zygote_J_to_packed_J(J)
  alphas = reshape(J[1], :)
  means = reshape(J[2], :)
  icf_unpacked = map(1:k) do Q_idx
    Q = J[3][:, :, Q_idx]
    lt_rows = map(2:d) do row
      Q[row, 1:row-1]
    end
    vcat(diag(Q), lt_rows...)
  end
  icf = collect(Iterators.flatten(icf_unpacked))
  packed_J = vcat(alphas, means, icf)
  packed_J
end

write_J(string(fn_out,"_J_",name,".txt"), zygote_J_to_packed_J(J))
write_times(string(fn_out,"_times_",name,".txt"),tf,tJ)