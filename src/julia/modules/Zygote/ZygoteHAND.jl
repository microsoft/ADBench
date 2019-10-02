module ZygoteHAND
include("../../shared/load.jl")
using ADPerfTest
using HandData
using Zygote

export get_hand_test

# objective

mutable struct ZygoteHandContext
    input::Union{HandInput, Nothing}
    iscomplicated::Bool
    wrapper_hand_objective::Union{Function, Nothing}
    objective::Vector{Float64}
    zygote_jacobian
end

function zygote_hand_prepare!(ctx::ZygoteHandContext, input::HandInput)
    # Running Zygote.gradient with test input, because the first invocation
    # of gradient on a given function is very long.
    # Using test input ensures that all computations related to the actual input
    # are done in calculate_jacobian!

    ctx.input = input
    #ctx.wrapper_hand_objective = (main_params, extra_params) -> lstmobjective(main_params, extra_params, input.state, input.sequence)
end

function zygote_hand_calculate_objective!(ctx::ZygoteHandContext, times)
    for i in 1:times
        #ctx.objective = lstmobjective(ctx.input.main_params, ctx.input.extra_params, ctx.input.state, ctx.input.sequence)
    end
end

function zygote_hand_calculate_jacobian!(ctx::ZygoteHandContext, times)
    for i in 1:times
        #ctx.zygote_gradient = Zygote.gradient(ctx.wrapper_hand_objective, ctx.input.main_params, ctx.input.extra_params)
    end
end

function zygote_hand_output!(out::HandOutput, ctx::ZygoteHandContext)
    #out.objective = ctx.objective
    #out.jacobian = pack_zygote_gradient(ctx.zygote_gradient...)
end

get_hand_test() = Test{HandInput, HandOutput}(
    ZygoteHandContext(nothing, false, nothing, [], nothing),
    zygote_hand_prepare!,
    zygote_hand_calculate_objective!,
    zygote_hand_calculate_jacobian!,
    zygote_hand_output!
)

end