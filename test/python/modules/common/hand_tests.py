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
from shared.input_utils import read_hand_instance
import utils



# root directory of python modules
MODULES_ROOT = os.path.join(PYTHON_ROOT, "modules")

# paths to the test data input
MODEL_PATH = os.path.join(ROOT, "data", "hand", "model")
SIMPLE_FILE_NAME = os.path.join(ROOT, "data", "hand", "test.txt")
COMPLICATED_FILE_NAME = os.path.join(
    ROOT,
    "data",
    "hand",
    "hand_complicated.txt"
)



# Parameters for different modules. They have the following form:
# {
#   "path": <module path relative to src/python/modules directory>,
#   "tolerance": <tolerance for module output results>
# }
test_params = [
    {
        "path": os.path.join("PyTorch", "PyTorchHand.py"),
        "tolerance": 1e-8
    }
]



class PythonModuleCommonHandTests(utils.BaseTestClass):
    '''Checking Hand objective differentiation in all python modules.''' 

    # helping functions
    def simple_objective_calculation_correctness(self, times):
        '''Checks objective calculation correctness running calculation
        several times when case is simple (without us).'''

        input = read_hand_instance(MODEL_PATH, SIMPLE_FILE_NAME, False)
        self.test.prepare(input)
        self.test.calculate_objective(times)
        output = self.test.output()

        expected_objective = [
            1.65193147941611551e-01,
            -1.74542769272742593e-01,
            1.54751161622253441e-01,
            -1.25651749731793605e-01,
            -4.25102935355075040e-02,
            -1.30665781132340175e-01
        ]

        self.assertFloatArrayEqual(
            expected_objective,
            output.objective,
            self.params["tolerance"]
        )

    def complicated_objective_calculation_correctness(self, times):
        '''Checks objective calculation correctness running calculation
        several times when case is complicated (with us).'''

        input = read_hand_instance(MODEL_PATH, COMPLICATED_FILE_NAME, True)
        self.test.prepare(input)
        self.test.calculate_objective(times)
        output = self.test.output()

        expected_objective = [
            0.15618766169646370,
            -0.14930052600332222,
            0.17223808982645483,
            -0.098877045184959655,
            -0.016123803546210125,
            -0.19758676846557965,
        ]

        self.assertFloatArrayEqual(
            expected_objective,
            output.objective,
            self.params["tolerance"]
        )

    def simple_jacobian_calculation_correctness(self, times):
        '''Checks jacobian calculation correctness running calculation
        several times when case is simple (without us).'''

        input = read_hand_instance(MODEL_PATH, SIMPLE_FILE_NAME, False)
        self.test.prepare(input)
        self.test.calculate_jacobian(times)
        output = self.test.output()

        # expected jacobian row by row
        expected_jacobian = [
            [ -1.955129593412827452e-02, 1.184213197364370439e-02, -1.081400434503667143e-02, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2.215372991798553182e-02, 2.980232943547148072e-02, -8.897183847208387994e-03, -2.248878879166987636e-03 ],
            [ -6.810275763693779405e-03, 1.741087975807761520e-03, -6.547316551062684620e-02, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1.426691754155922157e-02, 2.585199355653925585e-02, 2.304126225374846047e-03, 3.098952303155120668e-03 ],
            [ -4.093596307087540853e-02, 2.578361653626874000e-02, 2.955292530682450663e-03, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -3.123509052797571184e-02, -9.404299746840498811e-03, -1.847531451058702021e-02, -3.092118804974577050e-04 ],
            [ -7.100320031434406709e-02, 5.148925789858702778e-02, -6.334088540673042667e-02, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -3.453268937682813650e-02, -1.954375955878870363e-02, -1.291026286306825102e-02, 1.997381824883618772e-03, 0, 0, 0, 0 ],
            [ -2.813469291411112988e-02, -4.505919774927713561e-02, -8.981892000868592352e-02, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2.420245969624442925e-02, -1.843928141276340166e-02, 9.766062458045527556e-03, -1.425709141204036792e-03, 0, 0, 0, 0 ],
            [ -2.544841367831558385e-02, 6.239817382340766272e-02, 2.074409026714367846e-02, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -3.106756929938888495e-03, 6.527405427944250361e-03, 8.495535783899195795e-03, -4.354903199290739756e-04, 0, 0, 0, 0 ]
        ]

        self.assertFloatMatrixEqual(
            expected_jacobian,
            output.jacobian,
            self.params["tolerance"]
        )

    def complicated_jacobian_calculation_correctness(self, times):
        '''Checks jacobian calculation correctness running calculation
        several times when case is complicated (with us).'''

        input = read_hand_instance(MODEL_PATH, COMPLICATED_FILE_NAME, True)
        self.test.prepare(input)
        self.test.calculate_jacobian(times)
        output = self.test.output()

        # expected jacobian row by row
        expected_jacobian = np.array([
            [
                3.199947056506058374e-03,
                5.941210363247684256e-03,
                -3.167804141392804862e-02,
                2.512738463135467254e-02,
                -3.437516924900453630e-02,
                -1,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                -2.673004593049009732e-03,
                -2.053759644210334219e-04,
                0,
                0
            ],
            [
                -5.836643163521282318e-03,
                -2.250872721967178691e-02,
                -1.176031334552388521e-02,
                -6.734310052106870330e-03,
                -7.938243045385089125e-02,
                0,
                -1,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                2.519032062953539125e-03,
                6.357463656070681986e-03,
                0,
                0
            ],
            [
                5.265396983501258177e-03,
                -7.980309024706588872e-04,
                -4.003570128488601054e-02,
                4.485947794559119045e-02,
                1.089958676641684075e-02,
                0,
                0,
                -1,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                -1.657417678816148696e-03,
                2.115202844927725062e-03,
                0,
                0
            ],
            [
                6.095131076118365243e-03,
                4.723402593560632745e-03,
                -2.214244203888852958e-02,
                3.977514535737319834e-02,
                -8.704764000715992101e-02,
                -1,
                0,
                0,
                -3.338492634029291070e-03,
                1.282092206608171194e-03,
                0,
                0,
                1.372051239557433352e-03,
                -5.451772323756530828e-03,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0
            ],
            [
                -1.302730831274745427e-02,
                5.736485376990119178e-03,
                -9.037986689883760819e-03,
                -1.017850988759402830e-02,
                -4.370816495320522382e-02,
                0,
                -1,
                0,
                9.534582311269155846e-04,
                4.019722695933126977e-03,
                0,
                0,
                -9.336215180700850255e-04,
                -1.382224243492249840e-03,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0
            ],
            [
                -1.970549055737658151e-02,
                8.523712870960320487e-03,
                1.630197779552821497e-03,
                7.146464225044153740e-02,
                2.944031023744491521e-02,
                0,
                0,
                -1,
                3.249472449520837865e-03,
                8.499425893902214308e-04,
                0,
                0,
                -5.875374902405276420e-03,
                2.954942376134044382e-03,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0
            ]
        ])

        self.assertFloatMatrixEqual(
            expected_jacobian,
            output.jacobian,
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

    def test_simple_objective_calculation_correctness(self):
        '''Checks correctness of objective calculation over the single run
        for simple case (without us).'''

        self.simple_objective_calculation_correctness(times = 1)

    def test_simple_objective_multiple_times_calculation_correctness(self):
        '''Checks correctness of objective calculation over several runs
        for simple case (without us).'''

        self.simple_objective_calculation_correctness(times = 3)

    def test_complicated_objective_calculation_correctness(self):
        '''Checks correctness of objective calculation over the single run
        for complicated case (with us).'''

        self.complicated_objective_calculation_correctness(times = 1)

    def test_complicated_objective_multiple_times_calculation_correctness(self):
        '''Checks correctness of objective calculation over several runs
        for complicated case (with us).'''

        self.complicated_objective_calculation_correctness(times = 3)

    def test_simple_jacobian_calculation_correctness(self):
        '''Checks correctness of jacobian calculation over the single run
        for simple case (without us).'''

        self.simple_jacobian_calculation_correctness(times = 1)

    def test_simple_jacobian_multiple_times_calculation_correctness(self):
        '''Checks correctness of jacobian calculation over several runs
        for simple case (without us).'''

        self.simple_jacobian_calculation_correctness(times = 3)

    def test_complicated_jacobian_calculation_correctness(self):
        '''Checks correctness of jacobian calculation over the single run
        for complicated case (with us).'''

        self.complicated_jacobian_calculation_correctness(times = 1)

    def test_complicated_jacobian_multiple_times_calculation_correctness(self):
        '''Checks correctness of jacobian calculation over several runs
        for complicated case (with us).'''

        self.complicated_jacobian_calculation_correctness(times = 3)

    def test_simple_objective_runs_multiple_times(self):
        '''Checks if objective can be calculated multiple times
        for simple case (without us).'''

        input = read_hand_instance(MODEL_PATH, SIMPLE_FILE_NAME, False)
        self.test.prepare(input)

        func = self.test.calculate_objective
        self.assertTrue(utils.can_objective_run_multiple_times(func))

    def test_complicated_objective_runs_multiple_times(self):
        '''Checks if objective can be calculated multiple times
        for complicated case (with us).'''

        input = read_hand_instance(MODEL_PATH, COMPLICATED_FILE_NAME, True)
        self.test.prepare(input)

        func = self.test.calculate_objective
        self.assertTrue(utils.can_objective_run_multiple_times(func))

    def test_simple_jacobian_runs_multiple_times(self):
        '''Checks if jacobian can be calculated multiple times
        for simple case (without us).'''

        input = read_hand_instance(MODEL_PATH, SIMPLE_FILE_NAME, False)
        self.test.prepare(input)

        func = self.test.calculate_jacobian
        self.assertTrue(utils.can_objective_run_multiple_times(func))

    def test_complicated_jacobian_runs_multiple_times(self):
        '''Checks if jacobian can be calculated multiple times
        for complicated case (with us).'''

        input = read_hand_instance(MODEL_PATH, COMPLICATED_FILE_NAME, True)
        self.test.prepare(input)

        func = self.test.calculate_jacobian
        self.assertTrue(utils.can_objective_run_multiple_times(func))



if __name__ == "__main__":
    suite = unittest.TestSuite()
    for param_set in test_params:
        suite.addTest(utils.ParametrizedTestClass.parametrize(
            PythonModuleCommonHandTests,
            params = param_set
        ))

    res = unittest.TextTestRunner(verbosity = 2).run(suite)
    if res.wasSuccessful():
        sys.exit(0)
    else:
        sys.exit(1)