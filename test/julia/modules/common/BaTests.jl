module BaTests

dir = @__DIR__
ba_test_implementations = Tuple{String, Float64}[
    ("$dir/../../../../src/julia/modules/Zygote/ZygoteBA.jl", 1e-8)
]

map!(tup -> (abspath(tup[1]), tup[2]), ba_test_implementations, ba_test_implementations)

using Test
include("../../../../src/julia/shared/load.jl")
include("../../../../src/julia/runner/load.jl")
include("load.jl")
import ADPerfTest
import TestLoader
using BAData
using TestUtils

@testset "BA Module Tests" begin

@testset "BA Module Test ($(basename(module_path)))" for (module_path, tolerance) in ba_test_implementations
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
            test = TestLoader.get_ba_test(module_name)
            # Module loads
            @test isa(test, ADPerfTest.Test{BAInput, BAOutput})
            input = load_ba_input("$dir/../../../../data/ba/test.txt")
            test.prepare!(test.context, input)
            test.calculate_objective!(test.context, 1)
            output = empty_ba_output()
            test.output!(output, test.context)
            correct_reproj_err_elem = [ -2.69048849235189402e-01, 2.59944792677901881e-01]
            correct_w_err_elem = 8.26092651515999976e-01
            # Objective is calculated correctly
            @test (2, 10) == size(output.reproj_err)
            @test (10,) == size(output.w_err)
            for i ∈ 1:10
               @test correct_reproj_err_elem[1] ≈ output.reproj_err[1, i] atol=tolerance
               @test correct_reproj_err_elem[2] ≈ output.reproj_err[2, i] atol=tolerance
            end
            for i ∈ 1:10
               @test correct_w_err_elem ≈ output.w_err[i] atol=tolerance
            end
            test.calculate_objective!(test.context, 3)
            test.output!(output, test.context)
            # Objective is calculated correctly for time == 3
            @test (2, 10) == size(output.reproj_err)
            @test (10,) == size(output.w_err)
            for i ∈ 1:10
               @test correct_reproj_err_elem[1] ≈ output.reproj_err[1, i] atol=tolerance
               @test correct_reproj_err_elem[2] ≈ output.reproj_err[2, i] atol=tolerance
            end
            for i ∈ 1:10
               @test correct_w_err_elem ≈ output.w_err[i] atol=tolerance
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