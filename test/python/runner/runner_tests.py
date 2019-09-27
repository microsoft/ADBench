import unittest
import sys
from os import path

# adding folder with files for importing
sys.path.append(
    path.join(
        path.abspath(path.dirname(__file__)),
        "..",
        "..",
        "..",
        "src",
        "python"
    )
)

from unittest.mock import Mock
from time import sleep
from math import ceil

from runner.ModuleLoader import module_load
from runner.Benchmark import    measure_shortest_time,\
                                find_repeats_for_minimum_measurable_time,\
                                measurable_time_not_achieved

class PythonRunnerTests(unittest.TestCase):

    def test_ModuleLoad(self):
        module_path = path.join(
        path.abspath(path.dirname(__file__)), "MockModule.py")
        test = module_load(module_path)
        self.assertIsNotNone(test)

    def test_TimeLimit(self):
        # Run_count guarantees total time greater than the time_limit
        run_count = 100
        time_limit = 0.1 # seconds
        # Execution_time should be more than minimum_measurable_time 
        # because we can expect find_repeats_for_minimum_measurable_time
        # to call calculate_objective function only once in that case.
        minimum_measurable_time = 0 # seconds
        execution_time = 0.01 # seconds
        counter = 0

        def objective(_int):
            nonlocal counter
            counter += 1
            sleep(execution_time)

        measure_shortest_time(minimum_measurable_time, run_count, time_limit, objective)
        # Number of runs should be less then run_count variable because total_time will be reached.
        self.assertLessEqual(counter, ceil(time_limit / execution_time))

    def test_NumberOfRunsLimit(self):
        # Run_count guarantees total time lesser than the time_limit
        run_count = 10
        time_limit = 10.0
        # Execution_time should be more than minimum_measurable_time
        # because we can expect find_repeats_for_minimum_measurable_time
        # to call calculate_objective function only once in that case.
        minimum_measurable_time = 0.0
        execution_time = 0.01
        counter = 0

        def objective(_int):
            nonlocal counter
            counter += 1
            sleep(execution_time)

        measure_shortest_time(minimum_measurable_time, run_count, time_limit, objective)
        # Number of runs should be equal to run_count variable because total_time won't be reached.
        self.assertEqual(counter, run_count)

    def test_TimeMeasurement(self):
        # Run_count guarantees total time lesser than the time_limit
        run_count = 10
        time_limit = 100000.0
        # Execution_time should be more than minimum_measurable_time
        # because we can expect find_repeats_for_minimum_measurable_time
        # to call calculate_objective function only once in that case.
        minimum_measurable_time = 0.0
        execution_time = 0.01
        counter = 0

        def objective(_int):
            nonlocal counter
            counter += 1
            sleep(execution_time)

        shortest_time = measure_shortest_time(minimum_measurable_time, run_count, time_limit, objective)
        # Number of runs should be equal to run_count variable because total_time won't be reached.
        self.assertEqual(counter, run_count)
        self.assertGreaterEqual(shortest_time, execution_time)

    def test_SearchForRepeats(self):
        assumed_repeats = 16
        execution_time = 0.01
        minimum_measurable_time = execution_time * assumed_repeats

        calculate_objective = lambda repeats: sleep(repeats * execution_time)

        result = find_repeats_for_minimum_measurable_time(minimum_measurable_time, calculate_objective)
        self.assertNotEqual(result.repeats, measurable_time_not_achieved)
        self.assertLessEqual(result.repeats, assumed_repeats)

    def test_RepeatsNotFound(self):
        minimum_measurable_time = 1000.0

        calculate_objective = lambda repeats: None

        result = find_repeats_for_minimum_measurable_time(minimum_measurable_time, calculate_objective)
        self.assertEqual(result.repeats, measurable_time_not_achieved)

if __name__ == '__main__':
    unittest.main()