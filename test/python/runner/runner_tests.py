import unittest
import sys
sys.path.append(sys.path[0] + ("/" if sys.path[0] else None) + "../../../src/python/")
from runner.ModuleLoader import ModuleLoader
# from runner.main import main as main_test

class PythonRunnerTests(unittest.TestCase):

    def test_ModuleLoad(self):
        module_path = sys.path[0] + ("/" if sys.path[0] else None) + "MockGMM.py"
        module_loader = ModuleLoader(module_path)
        test = module_loader.get_test()
        self.assertIsNotNone(test)

    # def test_B(self):
    #     self.fail("Not implemented")
    # def test_C(self):
    #     self.assertEqual(0,
    #     main_test([self, "GMM", r"C:\Users\egoro\ADB/tools/PyTorch/PyTorch_gmm.py", r"C:\Users\egoro\ADB/data/gmm/1k/gmm_d2_K5.txt", r"C:\Users\egoro\ADB/tmp/Debug/gmm/1k/PyTorch/", 10, 10, 10, 2]))

if __name__ == '__main__':
    unittest.main()