import unittest
import sys
sys.path.append(sys.path[0] + ("/" if sys.path[0] else None) + "../../../src/python/")
from runner.ModuleLoader import ModuleLoader

class PythonRunnerTests(unittest.TestCase):

    def test_ModuleLoad(self):
        module_path = sys.path[0] + ("/" if sys.path[0] else None) + "MockGMM.py"
        module_loader = ModuleLoader(module_path)
        test = module_loader.get_test()
        self.assertIsNotNone(test)

if __name__ == '__main__':
    unittest.main()