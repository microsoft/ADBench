# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

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
    (ctx, times) -> nothing,
    (out, ctx) -> begin out.objective = 1.0 end
)

end