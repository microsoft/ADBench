# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

module Benchmark
include("load.jl")
include("../shared/load.jl")
using ADPerfTest
using TestLoader
using GMMData
using BAData
using HandData
using LSTMData
using DataUtils

export run_benchmark

const measurable_time_not_achieved = -1

"""
    find_repeats_for_minimum_measurable_time!(context, minimum_measurable_time, func)

Finds the number of repeats that `func` needs to be asked to compute its objective
in order to to run for at least `minimum_measurable_time` seconds.
`func` must have a method `func(::typeof(context), repeats::Int)`. That is the method
that will be tested.

Returns a tuple `(repeats, min_sample, total_time)`, where
`repeats` is the found necessary number of repeats,
`min_sample` is the minimal encountered value of
`@elapsed func(context, repeats) / repeats`
`total_time` is the total time spent on running `func` in seconds.
"""
function find_repeats_for_minimum_measurable_time!(context::Any, minimum_measurable_time::Float64, func::Function)
    total_time = 0.0
    min_sample = floatmax(Float64)
    repeats = 1
    max_possible_power_of_two = typemax(Int) ÷ 2 + 1
    while true
        current_run_time = @elapsed func(context, repeats)
        if current_run_time > minimum_measurable_time
            current_sample = current_run_time / repeats
            min_sample = min(min_sample, current_sample)
            total_time += current_run_time
            break
        end
        # The next iteration will overflow a loop counter that's why we recognize that we cannot reach the minimum measurable time.
        if repeats == max_possible_power_of_two
            repeats = measurable_time_not_achieved
            break
        end
        repeats *= 2
    end
    repeats, min_sample, total_time
end

"Benchmarks func according to the methodology described in docs/Methodology.md"
function measure_shortest_time!(context::Any, minimum_measurable_time::Float64, nruns::Int, time_limit::Float64, func::Function)::Float64
    precompile(func, (typeof(context), Int))
    repeats, min_sample, total_time = find_repeats_for_minimum_measurable_time!(context, minimum_measurable_time, func)
    if repeats == measurable_time_not_achieved
        throw(ErrorException("It was not possible to reach the number of repeats sufficient to achieve the minimum measurable time."))
    end
    # Recount `time_limit` and `run` from 0, despite "find_repeats_for_minimum_measurable_time",
    # because there might be lazy intializations
    total_time = 0.0
    run = 0
    while run < nruns && total_time < time_limit
        current_run_time = @elapsed func(context, repeats)
        min_sample = min(min_sample, current_run_time / repeats)
        total_time += current_run_time
        run += 1
    end
    min_sample
end

"Performs the entire benchmark process according to the methodology described in docs/Methodology.md"
function run_benchmark(
    input::Input,
    input_name::AbstractString,
    module_name::AbstractString,
    output_prefix::AbstractString,
    module_display_name::AbstractString,
    minimum_measurable_time::Float64,
    nruns_f::Int,
    nruns_J::Int,
    time_limit::Float64
) where Input
    output = create_empty_output_for(input)
    test = get_test_for(input, output, module_name)
    # Callbacks defined in test exist only in the latest world
    Base.invokelatest() do
        test.prepare!(test.context, input)

        objective_time = measure_shortest_time!(test.context, minimum_measurable_time, nruns_f, time_limit, test.calculate_objective!)
        derivative_time = measure_shortest_time!(test.context, minimum_measurable_time, nruns_J, time_limit, test.calculate_jacobian!)

        test.output!(output, test.context)

        save_time_to_file(times_file_name(output_prefix, input_name, module_display_name), objective_time, derivative_time)
        save_output_to_file(output, output_prefix, input_name, module_display_name)
    end
end

end
