module ZygoteLSTM
include("../../shared/load.jl")
using ADPerfTest
using LSTMData
using Zygote

export get_lstm_test

# objective
function sigmoid(x::Float64)
    1. / (1. + exp(-x))
end

function lstmmodel(weight::T1, bias::T2, hidden::T3, cell::T4, input::T5)::Tuple{Vector{Float64}, Vector{Float64}} where {T1<:AbstractVector{Float64}, T2<:AbstractVector{Float64}, T3<:AbstractVector{Float64}, T4<:AbstractVector{Float64}, T5<:AbstractVector{Float64}}
    hsize = size(hidden, 1)
    forget = sigmoid.(input .* view(weight, 1:hsize) .+ view(bias, 1:hsize))
    ingate = sigmoid.(hidden .* view(weight, hsize+1:2hsize) .+ view(bias, hsize+1:2hsize))
    outgate = sigmoid.(input .* view(weight, 2hsize+1:3hsize) .+ view(bias, 2hsize+1:3hsize))
    change = tanh.(hidden .* view(weight, 3hsize+1:4hsize) .+ view(bias, 3hsize+1:4hsize))

    cell2 = cell .* forget .+ ingate .* change
    hidden2 = outgate .* tanh.(cell2)
    hidden2, cell2
end

function lstmpredict(main_params::Matrix{Float64}, extra_params::Matrix{Float64}, state::Matrix{Float64}, input::T)::Tuple{Vector{Float64}, Matrix{Float64}} where {T<:AbstractVector{Float64}}
    x1 = input .* view(extra_params, :, 1)
    x = view(x1, :)
    lenstate = size(state, 2)
    s2 = Matrix{Float64}(undef, size(input, 1), 0)
    for i ∈ 1:2:lenstate
        h, c = lstmmodel(view(main_params, :, i), view(main_params, :, i + 1), view(state, :, i), view(state, :, i + 1), x)
        x = h
        # Zygote does not support mutating arrays
        # TODO: rewrite as array comprehension - initial attempts
        # were not successfully differentiated by Zygote
        s2 = hcat(s2, h, c)
    end
    (x .* view(extra_params, :, 2) .+ view(extra_params, :, 3), s2)
end

function lstmobjective(main_params::Matrix{Float64}, extra_params::Matrix{Float64}, state::Matrix{Float64}, sequence::Matrix{Float64})::Float64
    total = 0.
    count = 0
    input = view(sequence, :, 1)
    b, c = size(sequence)
    curstate = state
    for t ∈ 1:c-1
        ypred, curstate = lstmpredict(main_params, extra_params, curstate, input)
        ynorm = ypred .- log(sum(exp, ypred) + 2.)
        ygold = view(sequence, :, t + 1)
        total += sum(ygold .* ynorm)
        count += b
        input = ygold
    end
    -total / count
end

function pack_zygote_gradient(main_params_grad::Matrix{Float64}, extra_params_grad::Matrix{Float64})
    vcat(reshape(main_params_grad, :), reshape(extra_params_grad, :))
end

mutable struct ZygoteLSTMContext
    input::Union{LSTMInput, Nothing}
    wrapper_lstm_objective::Union{Function, Nothing}
    objective::Float64
    zygote_gradient::Tuple{Matrix{Float64}, Matrix{Float64}}
end

function zygote_lstm_prepare!(ctx::ZygoteLSTMContext, input::LSTMInput)
    # Running Zygote.gradient with test input, because the first invocation
    # of gradient on a given function is very long.
    # Using test input ensures that all computations related to the actual input
    # are done in calculate_jacobian!
    testmainparams = [1. 1.; 1. 1.; 1. 1.; 1. 1.]
    testextraparams = [1. 1. 1.]
    teststate = [1. 1.]
    testsequence = [1. 1.]
    testwrapper_lstm_objective = (main_params, extra_params) -> lstmobjective(main_params, extra_params, teststate, testsequence)
    Zygote.gradient(testwrapper_lstm_objective, testmainparams, testextraparams)

    ctx.input = input
    ctx.wrapper_lstm_objective = (main_params, extra_params) -> lstmobjective(main_params, extra_params, input.state, input.sequence)
end

function zygote_lstm_calculate_objective!(ctx::ZygoteLSTMContext, times)
    for i in 1:times
        ctx.objective = lstmobjective(ctx.input.main_params, ctx.input.extra_params, ctx.input.state, ctx.input.sequence)
    end
end

function zygote_lstm_calculate_jacobian!(ctx::ZygoteLSTMContext, times)
    for i in 1:times
        ctx.zygote_gradient = Zygote.gradient(ctx.wrapper_lstm_objective, ctx.input.main_params, ctx.input.extra_params)
    end
end

function zygote_lstm_output!(out::LSTMOutput, ctx::ZygoteLSTMContext)
    out.objective = ctx.objective
    out.gradient = pack_zygote_gradient(ctx.zygote_gradient...)
end

get_lstm_test() = Test{LSTMInput, LSTMOutput}(
    ZygoteLSTMContext(nothing, nothing, 0, (Matrix{Float64}(undef, 0, 0), Matrix{Float64}(undef, 0, 0))),
    zygote_lstm_prepare!,
    zygote_lstm_calculate_objective!,
    zygote_lstm_calculate_jacobian!,
    zygote_lstm_output!
)

end