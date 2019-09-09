module RunnerTests
using Test

include("../../../src/julia/shared/load.jl")
include("../../../src/julia/runner/load.jl")
import ADPerfTest
using GMMData
import TestLoader
import Benchmark

mockgmmcalcname = "Mock" * "GMM"

dir = @__DIR__
if !(dir ∈ LOAD_PATH)
    push!(LOAD_PATH, dir)
end

mutable struct Counter
    count::Int
    Counter() = new(0)
end

@testset "Runner Tests" begin
    @testset "Module Loading" begin
        @test isa(TestLoader.get_gmm_test(mockgmmcalcname), ADPerfTest.Test{GMMInput,GMMOutput})
        @test_throws ArgumentError TestLoader.get_ba_test(mockgmmcalcname)
        test = TestLoader.get_gmm_test(mockgmmcalcname)
        output = empty_gmm_output()
        test.output!(output, test.context)
        @test output.objective == 1.0
        test = TestLoader.get_gmm_test(mockgmmcalcname * "2")
        output = empty_gmm_output()
        test.output!(output, test.context)
        @test output.objective == 2.0
    end

    @testset "Time Limit" begin
        # Run_count guarantees total time greater than the time_limit
        run_count = 100
        time_limit = 0.1
        # Execution_time should be more than minimum_measurable_time
        # because we can expect find_repeats_for_minimum_measurable_time
        # to call calculate_objective function only once in that case.
        minimum_measurable_time = 0.0
        execution_time = 0.01
        ctx = Counter()
        objective(ctx, ::Int) = begin ctx.count += 1; sleep(execution_time) end
        Benchmark.measure_shortest_time!(ctx, minimum_measurable_time, run_count, time_limit, objective)
        # Number of runs should be less then run_count variable because total_time will be reached.
        @test ctx.count ≤ ceil(time_limit / execution_time)
    end

    @testset "Number of Runs Limit" begin
        # Run_count guarantees total time lesser than the time_limit
        run_count = 10
        time_limit = 10.0
        # Execution_time should be more than minimum_measurable_time
        # because we can expect find_repeats_for_minimum_measurable_time
        # to call calculate_objective function only once in that case.
        minimum_measurable_time = 0.0
        execution_time = 0.01
        ctx = Counter()
        objective(ctx, ::Int) = begin ctx.count += 1; sleep(execution_time) end
        Benchmark.measure_shortest_time!(ctx, minimum_measurable_time, run_count, time_limit, objective)
        # Number of runs should be equal to run_count variable because total_time won't be reached.
        @test ctx.count == run_count
    end

    @testset "Time Measurement" begin
        # Run_count guarantees total time lesser than the time_limit
        run_count = 10
        time_limit = 100000.0
        # Execution_time should be more than minimum_measurable_time
        # because we can expect find_repeats_for_minimum_measurable_time
        # to call calculate_objective function only once in that case.
        minimum_measurable_time = 0.0
        execution_time = 0.01
        ctx = Counter()
        objective(ctx, ::Int) = begin ctx.count += 1; sleep(execution_time) end
        shortest_time = Benchmark.measure_shortest_time!(ctx, minimum_measurable_time, run_count, time_limit, objective)
        # Number of runs should be equal to run_count variable because total_time won't be reached.
        @test ctx.count == run_count
        @test shortest_time ≥ execution_time
    end

    @testset "Search for Repeats" begin
        assumed_repeats = 16
        execution_time = 0.01
        minimum_measurable_time = execution_time * assumed_repeats
        ctx = Counter()
        objective(ctx, repeats) = begin sleep(repeats * execution_time) end
        repeats, _, _ = Benchmark.find_repeats_for_minimum_measurable_time!(ctx, minimum_measurable_time, objective)
        @test repeats ≠ Benchmark.measurable_time_not_achieved
        @test repeats ≤ assumed_repeats
    end

    @testset "Repeats Not Found" begin
        minimum_measurable_time = 1000.0
        ctx = Counter()
        objective(ctx, repeats) = nothing
        repeats, _, _ = Benchmark.find_repeats_for_minimum_measurable_time!(ctx, minimum_measurable_time, objective)
        @test repeats == Benchmark.measurable_time_not_achieved
    end
end
end