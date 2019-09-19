import importlib.util
from os.path import split

class ModuleLoader:
    def __init__(self, module_path):
        self.test = None
        self._class = None
        self.module_path = module_path

    # return test specified by module_path
    def get_test(self):
        # Module name should be the same as class name in that module
        # Get class name from args       
        class_name = split(self.module_path)[1].rsplit('.')[0]

        # import module
        spec = importlib.util.spec_from_file_location(class_name, self.module_path)
        if spec != None:
            self.test = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(self.test)

            # get class from module
            self._class = getattr(self.test, class_name)
            return self._class
        else:
            raise RuntimeError("Can't load module with path: " + self.module_path)