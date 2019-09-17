module TestUtils
include("../../../../src/julia/shared/load.jl")
include("../../../../src/julia/runner/load.jl")
using ADPerfTest
import Benchmark

export can_objective_run_multiple_times!

"""
    can_objective_run_multiple_times!(context, objective)

Checks whether `objective` function of some `Test<Input, Output>` instance runs for different time when the supplied
times parameter is different. To do so this function uses `Benchmark.find_repeats_for_minimum_measurable_time`
function. It tries to find such a minimum_measurable_time that `find_repeats_for_minimum_measurable_time` will 
return a number of repeats other than `1` or `measurable_time_not_achieved`.
If `objective` ignores its times parameter, we won't be able to find it.

# Arguments
- `context::Any`: `context` field of some `Test<Input, Output>` object.
- `objective::Function`: either `calculate_objective!` or `calculate_jacobian!` field of
the same `Test<Input, Output>` object.
"""
function can_objective_run_multiple_times!(context::Any, objective::Function)
    minimum_measurable_time = 0.05
    repeats, _, total_time = Benchmark.find_repeats_for_minimum_measurable_time!(context, minimum_measurable_time, objective)
    while (repeats == 1)
        # minimum_measurable_time * 2 ensures, that minimum_measurable_time * 2 will grow, while
        # result.total_time * 2 is a good guess for the time needed for at least 2 repeats
        minimum_measurable_time = max(minimum_measurable_time * 2, total_time * 2);
        repeats, _, total_time = Benchmark.find_repeats_for_minimum_measurable_time!(context, minimum_measurable_time, objective)
    end
    repeats ≠ Benchmark.measurable_time_not_achieved
end

end