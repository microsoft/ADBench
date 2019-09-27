import os
import sys
import unittest
import time

# adding folder with files for importing
sys.path.append(
    os.path.abspath(os.path.join(
        os.path.abspath(os.path.dirname(__file__)),
        "..",
        "..",
        "..",
        "..",
        "src",
        "python"
    )
))

from runner.Benchmark import find_repeats_for_minimum_measurable_time, \
                             measurable_time_not_achieved



class TestClassWithAdditionalAsserts(unittest.TestCase):
    '''This class contains additional assert functions.'''

    def assertFloatEqual(self, expected, given, precision = 1e-7):
        '''Asserts two doubles equality with the given precision.'''

        self.assertTrue(
            abs(expected - given) < precision,
            msg = f"{expected} != {given} with precision {precision}"
        )

    def assertFloatArrayEqual(self, expected, given, precision = 1e-7):
        '''Asserts two double array componentwise equality with the given
        precision.'''

        len_exp = len(expected)
        len_given = len(given)
        self.assertEqual(
            len_exp,
            len_given,
            msg = f"Arrays are of different length ({len_exp} != {len_given})"
        )

        for i in range(len_exp):
            self.assertTrue(
                abs(expected[i] - given[i]) < precision,
                msg = (
                    f"{i}th elements differ: "
                    f"{expected[i]} != {given[i]} with precision {precision}"
                )
            )



class ParametrizedTestClass(unittest.TestCase):
    '''Test class with parametrization.'''

    def __init__(self, method_name, params = None):
        super(ParametrizedTestClass, self).__init__(method_name)
        self.params = params

    @staticmethod
    def parametrize(test_cls, params):
        ''' Creates a suite containing all tests taken from the given
        test class, passing them the given parameters.
        '''

        testloader = unittest.TestLoader()
        testnames = testloader.getTestCaseNames(test_cls)
        suite = unittest.TestSuite()

        for name in testnames:
            suite.addTest(test_cls(name, params = params))

        return suite



class BaseTestClass(ParametrizedTestClass, TestClassWithAdditionalAsserts):
    '''Base class for all test classes.'''

    pass



def can_objective_run_multiple_times(func):
    '''Checks if the given module test class function can be run
    multiple times.
    
    Args:
        func (Callable[int]): function of one argument that means repeat
            count.
    '''

    minimum_measurable_time = 0.05
    result = find_repeats_for_minimum_measurable_time(
        minimum_measurable_time,
        func
    )

    while result.repeats == 1:
        # minimum_measurable_time * 2 ensures, that minimum_measurable_time * 2
        # will grow, while result.total_time * 2 is a good guess for the time
        # needed for at least 2 repeats

        minimum_measurable_time = max(
            minimum_measurable_time * 2,
            result.total_time * 2
        )

        result = find_repeats_for_minimum_measurable_time(
            minimum_measurable_time,
            func
        )

    return result.repeats != measurable_time_not_achieved