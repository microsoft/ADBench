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

            correct_jacobian_nrows = 30
            correct_jacobian_ncols = 62
            correct_jacobian_rows = [0, 15, 30, 45, 60, 75, 90, 105, 120, 135, 150, 165, 180, 195, 210, 225, 240, 255, 270, 285, 300, 301, 302, 303, 304, 305, 306, 307, 308, 309, 310]
            correct_jacobian_cols = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 22, 23, 24, 52, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 22, 23, 24, 52, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 25, 26, 27, 53, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 25, 26, 27, 53, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 28, 29, 30, 54, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 28, 29, 30, 54, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 31, 32, 33, 55, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 31, 32, 33, 55, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 34, 35, 36, 56, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 34, 35, 36, 56, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 37, 38, 39, 57, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 37, 38, 39, 57, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 40, 41, 42, 58, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 40, 41, 42, 58, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 43, 44, 45, 59, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 43, 44, 45, 59, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 46, 47, 48, 60, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 46, 47, 48, 60, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 49, 50, 51, 61, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 49, 50, 51, 61, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61]
            correct_jacobian_vals = [2.28877202208246757e+02, 6.34574811495545418e+02, -7.82222866259340549e+02, 2.42892615607159668e+00, -1.17828079628011313e+01, 2.54169312487743460e+00, -1.03657084958518086e+00, 4.17022000000000004e-01, 0.00000000000000000e+00, -3.50739521096005205e+02, -9.12107773668008576e+02, -2.42892615607159668e+00, 1.17828079628011313e+01, -2.54169312487743460e+00, -6.45167039712987389e-01, -1.20542435994996879e+02, -3.85673240766460424e+02, 9.75476291403326456e+01, -1.78372108529576567e+00, 4.15466799433126077e+00, 2.04025718029898906e+00, 3.49176397433145880e-01, 0.00000000000000000e+00, 4.17022000000000004e-01, 1.18149147704414503e+02, 3.07250108960343255e+02, 1.78372108529576567e+00, -4.15466799433126077e+00, -2.04025718029898906e+00, 6.23335921553064054e-01, 2.28877202208246757e+02, 6.34574811495545418e+02, -7.82222866259340549e+02, 2.42892615607159668e+00, -1.17828079628011313e+01, 2.54169312487743460e+00, -1.03657084958518086e+00, 4.17022000000000004e-01, 0.00000000000000000e+00, -3.50739521096005205e+02, -9.12107773668008576e+02, -2.42892615607159668e+00, 1.17828079628011313e+01, -2.54169312487743460e+00, -6.45167039712987389e-01, -1.20542435994996879e+02, -3.85673240766460424e+02, 9.75476291403326456e+01, -1.78372108529576567e+00, 4.15466799433126077e+00, 2.04025718029898906e+00, 3.49176397433145880e-01, 0.00000000000000000e+00, 4.17022000000000004e-01, 1.18149147704414503e+02, 3.07250108960343255e+02, 1.78372108529576567e+00, -4.15466799433126077e+00, -2.04025718029898906e+00, 6.23335921553064054e-01, 2.28877202208246757e+02, 6.34574811495545418e+02, -7.82222866259340549e+02, 2.42892615607159668e+00, -1.17828079628011313e+01, 2.54169312487743460e+00, -1.03657084958518086e+00, 4.17022000000000004e-01, 0.00000000000000000e+00, -3.50739521096005205e+02, -9.12107773668008576e+02, -2.42892615607159668e+00, 1.17828079628011313e+01, -2.54169312487743460e+00, -6.45167039712987389e-01, -1.20542435994996879e+02, -3.85673240766460424e+02, 9.75476291403326456e+01, -1.78372108529576567e+00, 4.15466799433126077e+00, 2.04025718029898906e+00, 3.49176397433145880e-01, 0.00000000000000000e+00, 4.17022000000000004e-01, 1.18149147704414503e+02, 3.07250108960343255e+02, 1.78372108529576567e+00, -4.15466799433126077e+00, -2.04025718029898906e+00, 6.23335921553064054e-01, 2.28877202208246757e+02, 6.34574811495545418e+02, -7.82222866259340549e+02, 2.42892615607159668e+00, -1.17828079628011313e+01, 2.54169312487743460e+00, -1.03657084958518086e+00, 4.17022000000000004e-01, 0.00000000000000000e+00, -3.50739521096005205e+02, -9.12107773668008576e+02, -2.42892615607159668e+00, 1.17828079628011313e+01, -2.54169312487743460e+00, -6.45167039712987389e-01, -1.20542435994996879e+02, -3.85673240766460424e+02, 9.75476291403326456e+01, -1.78372108529576567e+00, 4.15466799433126077e+00, 2.04025718029898906e+00, 3.49176397433145880e-01, 0.00000000000000000e+00, 4.17022000000000004e-01, 1.18149147704414503e+02, 3.07250108960343255e+02, 1.78372108529576567e+00, -4.15466799433126077e+00, -2.04025718029898906e+00, 6.23335921553064054e-01, 2.28877202208246757e+02, 6.34574811495545418e+02, -7.82222866259340549e+02, 2.42892615607159668e+00, -1.17828079628011313e+01, 2.54169312487743460e+00, -1.03657084958518086e+00, 4.17022000000000004e-01, 0.00000000000000000e+00, -3.50739521096005205e+02, -9.12107773668008576e+02, -2.42892615607159668e+00, 1.17828079628011313e+01, -2.54169312487743460e+00, -6.45167039712987389e-01, -1.20542435994996879e+02, -3.85673240766460424e+02, 9.75476291403326456e+01, -1.78372108529576567e+00, 4.15466799433126077e+00, 2.04025718029898906e+00, 3.49176397433145880e-01, 0.00000000000000000e+00, 4.17022000000000004e-01, 1.18149147704414503e+02, 3.07250108960343255e+02, 1.78372108529576567e+00, -4.15466799433126077e+00, -2.04025718029898906e+00, 6.23335921553064054e-01, 2.28877202208246757e+02, 6.34574811495545418e+02, -7.82222866259340549e+02, 2.42892615607159668e+00, -1.17828079628011313e+01, 2.54169312487743460e+00, -1.03657084958518086e+00, 4.17022000000000004e-01, 0.00000000000000000e+00, -3.50739521096005205e+02, -9.12107773668008576e+02, -2.42892615607159668e+00, 1.17828079628011313e+01, -2.54169312487743460e+00, -6.45167039712987389e-01, -1.20542435994996879e+02, -3.85673240766460424e+02, 9.75476291403326456e+01, -1.78372108529576567e+00, 4.15466799433126077e+00, 2.04025718029898906e+00, 3.49176397433145880e-01, 0.00000000000000000e+00, 4.17022000000000004e-01, 1.18149147704414503e+02, 3.07250108960343255e+02, 1.78372108529576567e+00, -4.15466799433126077e+00, -2.04025718029898906e+00, 6.23335921553064054e-01, 2.28877202208246757e+02, 6.34574811495545418e+02, -7.82222866259340549e+02, 2.42892615607159668e+00, -1.17828079628011313e+01, 2.54169312487743460e+00, -1.03657084958518086e+00, 4.17022000000000004e-01, 0.00000000000000000e+00, -3.50739521096005205e+02, -9.12107773668008576e+02, -2.42892615607159668e+00, 1.17828079628011313e+01, -2.54169312487743460e+00, -6.45167039712987389e-01, -1.20542435994996879e+02, -3.85673240766460424e+02, 9.75476291403326456e+01, -1.78372108529576567e+00, 4.15466799433126077e+00, 2.04025718029898906e+00, 3.49176397433145880e-01, 0.00000000000000000e+00, 4.17022000000000004e-01, 1.18149147704414503e+02, 3.07250108960343255e+02, 1.78372108529576567e+00, -4.15466799433126077e+00, -2.04025718029898906e+00, 6.23335921553064054e-01, 2.28877202208246757e+02, 6.34574811495545418e+02, -7.82222866259340549e+02, 2.42892615607159668e+00, -1.17828079628011313e+01, 2.54169312487743460e+00, -1.03657084958518086e+00, 4.17022000000000004e-01, 0.00000000000000000e+00, -3.50739521096005205e+02, -9.12107773668008576e+02, -2.42892615607159668e+00, 1.17828079628011313e+01, -2.54169312487743460e+00, -6.45167039712987389e-01, -1.20542435994996879e+02, -3.85673240766460424e+02, 9.75476291403326456e+01, -1.78372108529576567e+00, 4.15466799433126077e+00, 2.04025718029898906e+00, 3.49176397433145880e-01, 0.00000000000000000e+00, 4.17022000000000004e-01, 1.18149147704414503e+02, 3.07250108960343255e+02, 1.78372108529576567e+00, -4.15466799433126077e+00, -2.04025718029898906e+00, 6.23335921553064054e-01, 2.28877202208246757e+02, 6.34574811495545418e+02, -7.82222866259340549e+02, 2.42892615607159668e+00, -1.17828079628011313e+01, 2.54169312487743460e+00, -1.03657084958518086e+00, 4.17022000000000004e-01, 0.00000000000000000e+00, -3.50739521096005205e+02, -9.12107773668008576e+02, -2.42892615607159668e+00, 1.17828079628011313e+01, -2.54169312487743460e+00, -6.45167039712987389e-01, -1.20542435994996879e+02, -3.85673240766460424e+02, 9.75476291403326456e+01, -1.78372108529576567e+00, 4.15466799433126077e+00, 2.04025718029898906e+00, 3.49176397433145880e-01, 0.00000000000000000e+00, 4.17022000000000004e-01, 1.18149147704414503e+02, 3.07250108960343255e+02, 1.78372108529576567e+00, -4.15466799433126077e+00, -2.04025718029898906e+00, 6.23335921553064054e-01, 2.28877202208246757e+02, 6.34574811495545418e+02, -7.82222866259340549e+02, 2.42892615607159668e+00, -1.17828079628011313e+01, 2.54169312487743460e+00, -1.03657084958518086e+00, 4.17022000000000004e-01, 0.00000000000000000e+00, -3.50739521096005205e+02, -9.12107773668008576e+02, -2.42892615607159668e+00, 1.17828079628011313e+01, -2.54169312487743460e+00, -6.45167039712987389e-01, -1.20542435994996879e+02, -3.85673240766460424e+02, 9.75476291403326456e+01, -1.78372108529576567e+00, 4.15466799433126077e+00, 2.04025718029898906e+00, 3.49176397433145880e-01, 0.00000000000000000e+00, 4.17022000000000004e-01, 1.18149147704414503e+02, 3.07250108960343255e+02, 1.78372108529576567e+00, -4.15466799433126077e+00, -2.04025718029898906e+00, 6.23335921553064054e-01, -8.34044000000000008e-01, -8.34044000000000008e-01, -8.34044000000000008e-01, -8.34044000000000008e-01, -8.34044000000000008e-01, -8.34044000000000008e-01, -8.34044000000000008e-01, -8.34044000000000008e-01, -8.34044000000000008e-01, -8.34044000000000008e-01]
            
            test.calculate_jacobian!(test.context, 1)
            test.output!(output, test.context)
            # Jacobian is calculated correctly
            @test correct_jacobian_nrows == output.jacobian.nrows
            @test correct_jacobian_ncols == output.jacobian.ncols
            @test correct_jacobian_rows == output.jacobian.rows
            @test correct_jacobian_cols == output.jacobian.cols
            @test correct_jacobian_vals ≈ output.jacobian.vals atol=tolerance

            test.calculate_jacobian!(test.context, 3)
            test.output!(output, test.context)
            # Jacobian is calculated correctly for time == 3
            @test correct_jacobian_nrows == output.jacobian.nrows
            @test correct_jacobian_ncols == output.jacobian.ncols
            @test correct_jacobian_rows == output.jacobian.rows
            @test correct_jacobian_cols == output.jacobian.cols
            @test correct_jacobian_vals ≈ output.jacobian.vals atol=tolerance

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