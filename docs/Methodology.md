# Benchmarking Methodology

This document describes the process of obtaining time measurements for computations of objective functions and their derivatives using different automatic differentiation (AD) frameworks.

Benchmarking process depends on the following variables:
- `nruns_F` - maximum number of times to run the computation the objective function for timing
- `nruns_J` - maximum number of times to run the computation of the considered derivative (gradient or Jacobian) for timing
- `time_limit` - _soft_ (see below) time limit for benchmarking the computation of either the objective function or its gradient/Jacobian
- `timeout` - _hard_ time limit for the complete (including time that is not measured) benchmark
- `minimum_measurable_time` - minimum time, computation needs to run to produce a reliable measurement

The following is done for all combinations of considered AD frameworks and sets of parameters for all objective functions. If this process takes more time than `timeout`, it is forcibly stopped, and the result is considered to be 'time out'.

1. Read the input data and convert into a format fit for consumption by the AD framework being tested. _Time is not measured_.
1. Run any preparation code necessary to the AD framework, that is not AD itself. _Time is not measured_.
1. For both computation of the objective function and computation it gradient/Jacobian:
    1. Find the number of times computation needs to run consecutively, so that the total run time will be greater than `minimum_measurable_time`. To do that start with 1 and then test the consecutive powers of 2 until the `minimum_measurable_time` is reached. Denote the found number as `repeats`. Consider the last measured time divided by `repeats` to be the first sample.
    1. Continue time measuring the computation running for `repeats` times and producing new samples until either `nruns_F` (or `nruns_J` as appropriate) samples were produced, or total time taken to produce all current samples is greater than `time_limit`.
    1. Out of all the gathered samples pick the minimum. Most timing noise today is positive, except for clock resolution, which is alleviated by picking an appropriate `minimum_measurable_time`.
1. Save the minimal samples to a file. _Time is not measured_.
1. Save the result of the last computations for both objective function and its gradient/Jacobian in a standard format to a file to be compared to the correct results later. _Time is not measured_.

After this process is complete, the filesystem contains all the information necessary to
- Check the correctness of all finished computations
- Visualize the timings and/or their relations (e.g. we can plot the times for differentiation processes relative to the times for the computations of corresponding objective functions)