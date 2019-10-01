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
from shared.input_utils import read_gmm_instance
import utils



# root directory of python modules
MODULES_ROOT = os.path.join(PYTHON_ROOT, "modules")

# path to the file with test data input
TEST_INPUT_FILE_NAME = os.path.join(ROOT, "data", "gmm", "test.txt")



# Parameters for different modules. They have the following form:
# {
#   "path": <module path relative to src/python/modules directory>,
#   "tolerance": <tolerance for module res results>
# }
test_params = [
    {
        "path": os.path.join("PyTorch", "PyTorchGMM.py"),
        "tolerance": 1e-8
    }
]



class PythonModuleCommonGMMTests(utils.BaseTestClass):
    '''Checking GMM objective differentiation in all python modules.''' 

    # helping functions
    def objective_calculation_correctness(self, times):
        '''Checks objective calculation correctness running calculation
        several times.'''

        input = read_gmm_instance(TEST_INPUT_FILE_NAME, False)
        self.test.prepare(input)
        self.test.calculate_objective(times)
        output = self.test.output()

        self.assertFloatEqual(
            8.07380408004975791e+00,
            output.objective,
            self.params["tolerance"]
        )

    def jacobian_calculation_correctness(self, times):
        '''Checks jacobian calculation correctness running calculation
        several times.'''

        input = read_gmm_instance(TEST_INPUT_FILE_NAME, False)
        self.test.prepare(input)
        self.test.calculate_jacobian(times)
        output = self.test.output()

        expected_gradient = [
            1.08662855508652456e-01,
            -7.41270039523898472e-01,
            6.32607184015246071e-01,
            1.11692576532787013e+00,
            1.63333013551455269e-01,
            -2.19989824071193142e-02,
            2.27778292254236098e-01,
            1.20963025612832187e+00,
            -6.06375920733956339e-02,
            2.58529994051162237e+00,
            1.12632694524213789e-01,
            3.85744309849611777e-01,
            7.35180573182305508e-02,
            5.41836362715595232e+00,
            -3.21494409677446469e-01,
            1.71892309775004937e+00,
            8.60091090790866875e-01,
            -9.94640930466322848e-01
        ]

        self.assertFloatArrayEqual(
            expected_gradient,
            output.gradient,
            self.params["tolerance"]
        )



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

        input = read_gmm_instance(TEST_INPUT_FILE_NAME, False)
        self.test.prepare(input)

        func = self.test.calculate_objective
        self.assertTrue(utils.can_objective_run_multiple_times(func))

    def test_jacobian_runs_multiple_times(self):
        '''Checks if jacobian can be calculated multiple times.'''

        input = read_gmm_instance(TEST_INPUT_FILE_NAME, False)
        self.test.prepare(input)

        func = self.test.calculate_jacobian
        self.assertTrue(utils.can_objective_run_multiple_times(func))



if __name__ == "__main__":
    suite = unittest.TestSuite()
    for param_set in test_params:
        suite.addTest(utils.ParametrizedTestClass.parametrize(
            PythonModuleCommonGMMTests,
            params = param_set
        ))

    res = unittest.TextTestRunner(verbosity = 2).run(suite)
    if res.wasSuccessful():
        sys.exit(0)
    else:
        sys.exit(1)