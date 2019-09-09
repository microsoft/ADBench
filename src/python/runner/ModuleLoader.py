import importlib.util

class ModuleLoader:
    def __init__(self, module_path):
        self.test = None
        self.module_path = module_path

    # return test specified by module_path
    def get_test(self):
        if self.test != None:
            del self.test # DANGER here might be unexpected error: after deletion of self.test it might be created locally in get_test scope.
        spec = importlib.util.spec_from_file_location("get_test", self.module_path)
        self.test = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.test)
        if self.test != None:
            return self.test
        else:
            raise RuntimeError("Can't load module with path: " + self.module_path)