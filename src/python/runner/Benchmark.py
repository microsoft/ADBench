# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import time
import sys
import struct
from collections import namedtuple

from runner.ModuleLoader import module_load
from shared import GMMData
from shared import BAData
from shared import HandData
from shared import LSTMData
from runner.Filepaths import filepath_to_basename, modulepath_to_basename
from shared.output_utils import save_time_to_file

measurable_time_not_achieved = -1

def find_repeats_for_minimum_measurable_time(minimum_measurable_time, func):
    total_time = 0
    min_sample = sys.float_info.max

    repeats = 1
    # get platform C maxint & (maxint >> 1) + 1
    max_reasonable_number_of_repetitions = 2 ** (struct.Struct('i').size * 8 - 2)
    while True:
        t1 = time.time()
        func(repeats)
        t2 = time.time()
        # Time in seconds
        current_run_time = t2 - t1
        if current_run_time > minimum_measurable_time:
            current_sample = current_run_time / repeats
            min_sample = min(min_sample, current_sample)
            total_time += current_run_time
            break
        repeats *= 2
        # loop exit condition
        if repeats > max_reasonable_number_of_repetitions:
            # we recognize that we cannot reach the minimum measurable time.
            repeats = measurable_time_not_achieved
            break

    result = namedtuple('result', 'repeats, sample, total_time')
    return result(repeats = repeats, sample = min_sample, total_time = total_time)

# Measures time according to the documentation.
def measure_shortest_time(minimum_measurable_time, nruns, time_limit, func):
        find_repeats_result = find_repeats_for_minimum_measurable_time(minimum_measurable_time, func)

        if find_repeats_result.repeats == measurable_time_not_achieved:
            raise RuntimeError("It was not possible to reach the number of repeats sufficient to achieve the minimum measurable time.")

        repeats = find_repeats_result.repeats
        min_sample = find_repeats_result.sample
        total_time = find_repeats_result.total_time

        # "run" begins from 1 because a first run already done by "find_repeats_for_minimum_measurable_time" function
        run = 1
        while (run < nruns) and (total_time < time_limit):
            run += 1
            t1 = time.time()
            func(repeats)
            t2 = time.time()
            # Time in seconds
            current_run_time = t2 - t1
            min_sample = min(min_sample, current_run_time / repeats)
            total_time += current_run_time

        return min_sample

# Performs the entire benchmark process according to the documentation
def run_benchmark(module_path, input_filepath, _input, output_prefix, minimum_measurable_time, nruns_F, nruns_J, time_limit):

    test = module_load(module_path)

    test.prepare(_input)

    objective_time = measure_shortest_time(minimum_measurable_time, nruns_F, time_limit, test.calculate_objective)

    derivative_time = measure_shortest_time(minimum_measurable_time, nruns_J, time_limit, test.calculate_jacobian)

    output = test.output()

    input_basename = filepath_to_basename(input_filepath)
    module_basename = modulepath_to_basename(module_path)

    save_time_to_file(output_prefix + input_basename + "_times_" + module_basename + ".txt", objective_time, derivative_time)
    output.save_output_to_file(output_prefix, input_basename, module_basename)