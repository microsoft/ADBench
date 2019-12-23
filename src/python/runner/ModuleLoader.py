# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import importlib.util
from os.path import split

# return module specified by module_path
def module_load(module_path):
    '''
    Args:
        module_path (str): absolute path to the module.
            Module name should be the same as class name in that module.
    '''
    # Get class name from args
    class_name = split(module_path)[1].rsplit('.')[0]

    # import module
    spec = importlib.util.spec_from_file_location(class_name, module_path)
    if spec != None:
        test = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(test)

        # get class from module
        _class = getattr(test, class_name)
        return _class()
    else:
        raise RuntimeError("Can't load module with path: " + module_path)