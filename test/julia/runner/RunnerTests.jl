module RunnerTests
using Test

include("../../../src/julia/shared/load.jl")
include("../../../src/julia/runner/load.jl")
using ADPerfTest
import TestLoader

mockgmmcalcname = "Mock" * "GMM"

dir = @__DIR__
if !(dir ∈ LOAD_PATH)
    push!(LOAD_PATH, dir)
end

@testset "Module Loading" begin
    test = TestLoader.get_gmm_test(mockgmmcalcname)
    @test test.calculate_jacobian!(test.context, 10) === "m1"
    @test_throws ArgumentError TestLoader.get_ba_test(mockgmmcalcname)
    test = TestLoader.get_gmm_test(mockgmmcalcname * "2")
    @test test.calculate_jacobian!(test.context, 10) === "m2"

end

end