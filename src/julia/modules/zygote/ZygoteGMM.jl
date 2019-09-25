module ZygoteGMM
include("../../shared/load.jl")
using ADPerfTest
using GMMData
using Zygote
using Zygote: @adjoint
using SpecialFunctions
using LinearAlgebra

export get_gmm_test

"Computes logsumexp. Input should be 1 dimensional"
function logsumexp(x)
    mx = maximum(x)
    log(sum(exp.(x .- mx))) + mx
end

sumsq(v) = sum(abs2, v)

function ltri_unpack(D, LT)
    d = length(D)
    make_row(r::Int, L) = hcat(reshape([L[i] for i=1:r-1], 1, r - 1), D[r], zeros(1, d - r))
    row_start(r::Int) = (r - 1) * (r - 2) ÷ 2
    inds(r) = row_start(r) .+ (1:r-1)
    vcat([make_row(r, LT[inds(r)]) for r=1:d]...)
end
  
function get_Q(d, icf)
    ltri_unpack(exp.(icf[1:d]), icf[d+1:end])
end
  
function get_Q_zygote(d, icf)
    ltri_unpack((icf[1:d]), icf[d+1:end])
end
  
# Gradient helpers
function pack(alphas, means, icf)
    [alphas[:]; means[:]; icf[:]]
end
  
function unpack(d, k, packed)
    alphas = reshape(packed[1:k], 1, k)
    off = k
    means = reshape(packed[(1:d*k) .+ off], d, k)
    icf_sz = d * (d + 1) ÷ 2
    off += d * k
    icf = reshape(packed[off+1:end], icf_sz, k)
    (alphas, means, icf)
end
  
function log_gamma_distrib(a, p)
    out = 0.25 * p * (p - 1) * 1.1447298858494002 #convert(Float64, log(pi))
    out += sum(j -> loggamma(a + 0.5 * (1 - j)), 1:p) 
    out
end

@adjoint function loggamma(x)
    loggamma(x), Δ -> (Δ * digamma(x),)
end
  
function log_wishart_prior_zygote(wishart::Wishart, sum_qs, Qs, k)
    p = size(Qs, 1)
    n = p + wishart.m + 1
    C = n * p * (log(wishart.gamma) - 0.5 * log(2)) - log_gamma_distrib(0.5 * n, p)
  
    frobenius = sum(abs2, Qs)
	0.5 * wishart.gamma^2 * frobenius - wishart.m * sum(sum_qs) - k * C
end

function diagsums(Qs)
    mapslices(slice -> sum(diag(slice)), Qs; dims=[1, 2])
end
  
@adjoint function diagsums(Qs)
    diagsums(Qs),
    function (Δ)
        Δ′ = zero(Qs)
        for (i, δ) in enumerate(Δ)
            for j in 1:size(Qs, 1)
                Δ′[j, j, i] = δ
            end
        end
        (Δ′,)
    end
end
  
function expdiags(Qs)
    mapslices(Qs; dims=[1, 2]) do slice
        slice[diagind(slice)] .= exp.(slice[diagind(slice)])
        slice
    end
end
  
@adjoint function expdiags(Qs)
    expdiags(Qs),
    function (Δ)
        Δ′ = zero(Qs)
        Δ′ .= Δ
        for i in 1:size(Qs, 3)
            for j in 1:size(Qs, 1)
                Δ′[j, j, i] *= exp(Qs[j, j, i])
            end
        end
        (Δ′,)
    end
end
  
function unzip(tuples)
    map(1:length(first(tuples))) do i
        map(tuple -> tuple[i], tuples)
    end
end

@adjoint function map(f, args...)
    ys_and_backs = map((args...) -> Zygote._forward(__context__, f, args...), args...)
    ys, backs = unzip(ys_and_backs)
    ys, function (Δ)
        Δf_and_args_zipped = map((f, δ) -> f(δ), backs, Δ)
        Δf_and_args = unzip(Δf_and_args_zipped)
        Δf = reduce(Zygote.accum, Δf_and_args[1])
        (Δf, Δf_and_args[2:end]...)
    end
end
  
Base.:*(::Float64, ::Nothing) = nothing
  
function gmm_objective(alphas, means, Qs, x, wishart::Wishart)
    d = size(x, 1)
    n = size(x, 2)
    k = size(means, 2)
    CONSTANT = -n * d * 0.5 * log(2 * pi)
    sum_qs = reshape(diagsums(Qs), 1, size(Qs, 3))
    Qs = expdiags(Qs)
  
    main_term = zeros(Float64, 1, k)
  
    slse = 0.
    for ix=1:n
        formula(ik) = -0.5 * sum(abs2, Qs[:, :, ik] * (x[:,ix] .- means[:, ik]))
        sumexp = 0.
        for ik=1:k
            sumexp += exp(formula(ik) + alphas[ik] + sum_qs[ik])
        end
        slse += log(sumexp)
    end
  
    CONSTANT + slse - n * logsumexp(alphas) + log_wishart_prior_zygote(wishart, sum_qs, Qs, k)
end

function zygote_J_to_packed_J(J, k, d)
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

mutable struct ZygoteGMMContext
    input::Union{GMMInput, Nothing}
    Qs
    wrapper_gmm_objective::Union{Function, Nothing}
    objective::Float64
    zygote_J
end

function zygote_gmm_prepare!(ctx::ZygoteGMMContext, input::GMMInput)
    # Running Zygote.gradient with test input, because the first invocation
    # of gradient on a given function is very long.
    # Using test input ensures that all computations related to the actual input
    # are done in calculate_jacobian!
    testinput = load_gmm_input("$(@__DIR__)/../../../../data/gmm/test.txt", false)
    testd = size(testinput.x, 1)
    testk = size(testinput.means, 2)
    testQs = cat([get_Q_zygote(testd, testinput.icfs[:, ik]) for ik in 1:testk]...; dims=[3])
    test_wrapper_gmm_objective = (alphas, means, Qs) -> gmm_objective(alphas, means, Qs, testinput.x, testinput.wishart)
    Zygote.gradient(test_wrapper_gmm_objective, testinput.alphas, testinput.means, testQs)
    
    ctx.input = input
    d = size(input.x, 1)
    k = size(input.means, 2)
    ctx.Qs = cat([get_Q_zygote(d, input.icfs[:, ik]) for ik in 1:k]...; dims=[3])
    ctx.wrapper_gmm_objective = (alphas, means, Qs) -> gmm_objective(alphas, means, Qs, input.x, input.wishart)
end

function zygote_gmm_calculate_objective!(ctx::ZygoteGMMContext, times)
    for i in 1:times
        ctx.objective = gmm_objective(ctx.input.alphas, ctx.input.means, ctx.Qs, ctx.input.x, ctx.input.wishart)
    end
end

function zygote_gmm_calculate_jacobian!(ctx::ZygoteGMMContext, times)
    for i in 1:times
        ctx.zygote_J = Zygote.gradient(ctx.wrapper_gmm_objective, ctx.input.alphas, ctx.input.means, ctx.Qs)
    end
end

function zygote_gmm_output!(out::GMMOutput, ctx::ZygoteGMMContext)
    out.objective = ctx.objective
    d = size(ctx.input.x, 1)
    k = size(ctx.input.means, 2)
    out.gradient = ctx.zygote_J === nothing ? [] : zygote_J_to_packed_J(ctx.zygote_J, k, d)
end

get_gmm_test() = Test{GMMInput, GMMOutput}(
    ZygoteGMMContext(nothing, nothing, nothing, 0.0, nothing),
    zygote_gmm_prepare!,
    zygote_gmm_calculate_objective!,
    zygote_gmm_calculate_jacobian!,
    zygote_gmm_output!
)

end