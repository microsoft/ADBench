module GmmTests

dir = @__DIR__
gmm_test_implementations = String[
    "$dir/../../../../src/julia/modules/zygote/ZygoteGMM.jl"
]

map!(abspath, gmm_test_implementations, gmm_test_implementations)

using Test
include("../../../../src/julia/shared/load.jl")
include("../../../../src/julia/runner/load.jl")
import ADPerfTest
import TestLoader
using GMMData

@testset "GMM Module Tests" begin

@testset "GMM Module Test ($(basename(module_path)))" for module_path in gmm_test_implementations
    module_dir, module_filename = splitdir(module_path)
    module_name, module_ext = splitext(module_filename)
    ext_r = @test module_ext == ".jl"
    ispath_r = @test (ispath(module_path) && !isdir(module_path))
    if isa(ext_r, Test.Pass) && isa(ispath_r, Test.Pass)
        need_modify_load_path = !(module_dir ∈ LOAD_PATH)
        if need_modify_load_path
            push!(LOAD_PATH, module_dir)
        end
        try
            test = TestLoader.get_gmm_test(module_name)
            @test isa(test, ADPerfTest.Test{GMMInput,GMMOutput})
            input = load_gmm_input("$dir/../../../../data/gmm/test.txt", false)
            test.prepare!(test.context, input)
            test.calculate_objective!(test.context, 1)
            output = empty_gmm_output()
            test.output!(output, test.context)
            @test 8.0738 ≈ output.objective atol=0.00001
            test.calculate_jacobian!(test.context, 1)
            test.output!(output, test.context)
            @test 18 == size(output.gradient, 1)
            correct_grad = [ 0.108663, -0.74127, 0.632607, 1.116926, 0.163333, -0.022, 0.227778, 1.20963, -0.06064, 2.5853, 0.11263, 0.38574, 0.07352, 5.41836, -0.3215, 1.71892, 0.86009, -0.99464 ]
            for i ∈ 1:18
               @test correct_grad[i] ≈ output.gradient[i] atol=0.00001
            end
            
        finally
            pop!(LOAD_PATH)
        end
    end
end

end

end