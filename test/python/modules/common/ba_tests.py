import unittest
import numpy as np
import sys
import os

# root directory of the whole project
ROOT = os.path.abspath(os.path.join(
    os.path.abspath(os.path.dirname(__file__)),
    "..",
    "..",
    "..",
    ".."
))

# root directory of the python source
PYTHON_ROOT = os.path.join(ROOT, "src", "python")

# adding python src root directory for importing
sys.path.append(PYTHON_ROOT)

from runner.ModuleLoader import module_load
from shared.input_utils import read_ba_instance
import utils



# root directory of python modules
MODULES_ROOT = os.path.join(PYTHON_ROOT, "modules")

# path to the file with test data input
TEST_INPUT_FILE_NAME = os.path.join(ROOT, "data", "ba", "test.txt")



# Parameters for different modules. They have the following form:
# {
#   "path": <module path relative to src/python/modules directory>,
#   "tolerance": <tolerance for module output results>
# }
test_params = [
    {
        "path": os.path.join("PyTorch", "PyTorchBA.py"),
        "tolerance": 1e-8
    }
]



class PythonModuleCommonBATests(utils.BaseTestClass):
    '''Checking BA objective differentiation in all python modules.''' 

    # helping functions
    def objective_calculation_correctness(self, times):
        '''Checks objective calculation correctness running calculation
        several times.'''

        input = read_ba_instance(TEST_INPUT_FILE_NAME)
        self.test.prepare(input)
        self.test.calculate_objective(times)
        output = self.test.output()

        expected_weight_err = np.full(10, 8.26092651515999976e-01)
        expected_reproj_err = np.array(
            [ -2.69048849235189402e-01, 2.59944792677901881e-01 ] * 10
        )

        self.assertFloatArrayEqual(
            expected_reproj_err,
            output.reproj_err,
            self.params["tolerance"]
        )

        self.assertFloatArrayEqual(
            expected_weight_err,
            output.w_err,
            self.params["tolerance"]
        )

    def jacobian_calculation_correctness(self, times):
        '''Checks jacobian calculation correctness running calculation
        several times.'''

        input = read_ba_instance(TEST_INPUT_FILE_NAME)
        self.test.prepare(input)
        self.test.calculate_jacobian(times)
        output = self.test.output()

        # check jacobian shape
        self.assertEqual(30, output.J.nrows)
        self.assertEqual(62, output.J.ncols)
        self.assertEqual(31, len(output.J.rows))
        self.assertEqual(310, len(output.J.cols))
        self.assertEqual(310, len(output.J.vals))

        # check jacobian values
        eps = self.params["tolerance"]
        self.assertFloatEqual(2.28877202208246757e+02, output.J.vals[0], eps)
        self.assertFloatEqual(6.34574811495545418e+02, output.J.vals[1], eps)
        self.assertFloatEqual(-7.82222866259340549e+02, output.J.vals[2], eps)
        self.assertFloatEqual(2.42892615607159668e+00, output.J.vals[3], eps)
        self.assertFloatEqual(-1.17828079628011313e+01, output.J.vals[4], eps)
        self.assertFloatEqual(2.54169312487743460e+00, output.J.vals[5], eps)
        self.assertFloatEqual(-1.03657084958518086e+00, output.J.vals[6], eps)
        self.assertFloatEqual(4.17022000000000004e-01, output.J.vals[7], eps)
        self.assertFloatEqual(0.0, output.J.vals[8], eps)
        self.assertFloatEqual(-3.50739521096005205e+02, output.J.vals[9], eps)
        self.assertFloatEqual(-9.12107773668008576e+02, output.J.vals[10], eps)
        self.assertFloatEqual(-2.42892615607159668e+00, output.J.vals[11], eps)
        self.assertFloatEqual(1.17828079628011313e+01, output.J.vals[12], eps)
        self.assertFloatEqual(-8.34044000000000008e-01, output.J.vals[307], eps)
        self.assertFloatEqual(-8.34044000000000008e-01, output.J.vals[308], eps)
        self.assertFloatEqual(-8.34044000000000008e-01, output.J.vals[309], eps)



    # main test functions
    def setUp(self):
        module_path = os.path.join(MODULES_ROOT, self.params["path"])
        self.test = module_load(module_path)
        self.assertIsNotNone(self.test)

    def test_loading(self):
        '''Checks if modules can be loaded.'''

        pass    # all work is done in the setUp function

    def test_objective_calculation_correctness(self):
        '''Checks correctness of objective calculation over the single run.'''

        self.objective_calculation_correctness(times = 1)

    def test_objective_multiple_times_calculation_correctness(self):
        '''Checks correctness of objective calculation over several runs.'''

        self.objective_calculation_correctness(times = 3)

    def test_jacobian_calculation_correctness(self):
        '''Checks correctness of jacobian calculation over the single run.'''

        self.jacobian_calculation_correctness(times = 1)

    def test_jacobian_multiple_times_calculation_correctness(self):
        '''Checks correctness of jacobian calculation over the single run.'''

        self.jacobian_calculation_correctness(times = 3)

    def test_objective_runs_multiple_times(self):
        '''Checks if objective can be calculated multiple times.'''

        input = read_ba_instance(TEST_INPUT_FILE_NAME)
        self.test.prepare(input)

        func = self.test.calculate_objective
        self.assertTrue(utils.can_objective_run_multiple_times(func))

    def test_jacobian_runs_multiple_times(self):
        '''Checks if jacobian can be calculated multiple times.'''

        input = read_ba_instance(TEST_INPUT_FILE_NAME)
        self.test.prepare(input)

        func = self.test.calculate_jacobian
        self.assertTrue(utils.can_objective_run_multiple_times(func))



if __name__ == "__main__":
    suite = unittest.TestSuite()
    for param_set in test_params:
        suite.addTest(utils.ParametrizedTestClass.parametrize(
            PythonModuleCommonBATests,
            params = param_set
        ))

    res = unittest.TextTestRunner(verbosity = 2).run(suite)
    if res.wasSuccessful():
        sys.exit(0)
    else:
        sys.exit(1)