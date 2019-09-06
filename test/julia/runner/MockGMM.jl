module MockGMM

include("../../../src/julia/shared/load.jl")
using ADPerfTest
using GMMData

export get_gmm_test

mutable struct MockGMMContext
    waitcoef::Float64
end

get_gmm_test() = Test{GMMInput, GMMOutput}(
    MockGMMContext(2.0),
    (ctx, input) -> nothing,
    (ctx, times) -> nothing,
    (ctx, times) -> "m1",
    (out, ctx) -> nothing
)

end