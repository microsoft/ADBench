module GmmTests

dir = @__DIR__
gmm_test_implementations = Tuple{String, Float64}[
    ("$dir/../../../../src/julia/modules/Zygote/ZygoteGMM.jl", 1e-8)
]

map!(tup -> (abspath(tup[1]), tup[2]), gmm_test_implementations, gmm_test_implementations)

using Test
include("../../../../src/julia/shared/load.jl")
include("../../../../src/julia/runner/load.jl")
include("load.jl")
import ADPerfTest
import TestLoader
using GMMData
using TestUtils

@testset "GMM Module Tests" begin

@testset "GMM Module Test ($(basename(module_path)))" for (module_path, tolerance) in gmm_test_implementations
    module_dir, module_filename = splitdir(module_path)
    module_name, module_ext = splitext(module_filename)
    # Assert that the path to the module is correct
    ext_r = @test module_ext == ".jl"
    ispath_r = @test (ispath(module_path) && !isdir(module_path))
    if isa(ext_r, Test.Pass) && isa(ispath_r, Test.Pass)
        need_modify_load_path = !(module_dir ∈ LOAD_PATH)
        if need_modify_load_path
            push!(LOAD_PATH, module_dir)
        end
        try
            test = TestLoader.get_gmm_test(module_name)
            # Module loads
            @test isa(test, ADPerfTest.Test{GMMInput,GMMOutput})
            input = load_gmm_input("$dir/../../../../data/gmm/test.txt", false)
            output = empty_gmm_output()
            test.prepare!(test.context, input)
            test.calculate_objective!(test.context, 1)
            test.output!(output, test.context)
            # Objective is calculated correctly
            @test 8.07380408004975791e+00 ≈ output.objective atol=tolerance
            test.calculate_objective!(test.context, 3)
            test.output!(output, test.context)
            # Objective is calculated correctly for times = 3
            @test 8.07380408004975791e+00 ≈ output.objective atol=tolerance
            test.calculate_jacobian!(test.context, 1)
            test.output!(output, test.context)
            # Gradient is calculated correctly
            @test 18 == size(output.gradient, 1)
            correct_grad = [
                1.08662855508652456e-01,
                -7.41270039523898472e-01,
                6.32607184015246071e-01,
                1.11692576532787013e+00,
                1.63333013551455269e-01,
                -2.19989824071193142e-02,
                2.27778292254236098e-01,
                1.20963025612832187e+00,
                -6.06375920733956339e-02,
                2.58529994051162237e+00,
                1.12632694524213789e-01,
                3.85744309849611777e-01,
                7.35180573182305508e-02,
                5.41836362715595232e+00,
                -3.21494409677446469e-01,
                1.71892309775004937e+00,
                8.60091090790866875e-01,
                -9.94640930466322848e-01
            ]
            for i ∈ 1:18
               @test correct_grad[i] ≈ output.gradient[i] atol=tolerance
            end
            test.calculate_jacobian!(test.context, 3)
            test.output!(output, test.context)
            # Gradient is calculated correctly for times = 3
            @test 18 == size(output.gradient, 1)
            for i ∈ 1:18
               @test correct_grad[i] ≈ output.gradient[i] atol=tolerance
            end
            # Objective runs multiple times
            @test can_objective_run_multiple_times!(test.context, test.calculate_objective!)
            # Jacobian runs multiple times
            @test can_objective_run_multiple_times!(test.context, test.calculate_jacobian!)
        finally
            pop!(LOAD_PATH)
        end
    end
end

end

end