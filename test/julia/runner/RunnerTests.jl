module RunnerTests
using Test

include("../../../src/julia/shared/load.jl")
include("../../../src/julia/runner/load.jl")
using ADPerfTest
import TestLoader

#Base.require()
mockgmmpath = "Mock" * "GMM"# * ".jl"
#include(mockgmmpath)

dir = @__DIR__
println(dir)
if !(dir ∈ LOAD_PATH)
    push!(LOAD_PATH, dir)
end
#using MockGMM
#Base.require(RunnerTests, Symbol(mockgmmpath))
#Base.eval(Expr(:import, Symbol(mockgmmpath)))
#m = Module(Symbol(mockgmmpath))
#using RunnerTests.m

#module Box
#mockgmmpath = "Mock" * "GMM"
#include_string(Box, "using " * mockgmmpath)
#end

function loadtest(modulename::String)
    Box = Module()
    include_string(Box, "using " * mockgmmpath)
    @test isdefined(Box, :get_gmm_test)
    Base.invokelatest(Box.get_gmm_test)
end

@testset "hello" begin
    @test 1 == 1
    #@test isdefined(Box, :get_gmm_test)
    test = TestLoader.get_gmm_test(mockgmmpath)
    @test test.calculate_jacobian!(test.context, 10) === "m1"
    test = TestLoader.get_gmm_test(mockgmmpath * "2")
    @test test.calculate_jacobian!(test.context, 10) === "m2"

end

end