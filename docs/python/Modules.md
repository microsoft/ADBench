# Python Modules

## Adding new modules

1. Create a new folder in the directory `/src/python/modules` with the name equals to adding module name (let's suppose it is `<ModuleName>`).

2. Create an empty `__init__.py` file in your folder. This has to be done becuase `/src/python` folder is designed as a package.

3. For each objective create a class implementing abstract class `ITest` (it is defined in the file `/src/python/shared/ITest.py`). Your class name must have the form `<ModuleName><Objective>`, where `<Objective>` is the type of objective this class is created for (`BA`, `GMM` etc.). The class file must have the same name as the class itself (i.e. `<ModuleName><Objective>.py`). As far as the `/src/python` designed as a package, imports in your class files must be relative to `src/python` directory. E.g. 
    ```python
    from shared.ITest import ITest
    ```

    You need to implement the following methods:
    - ```python
      prepare(self, input)
      ```
        Performs some preliminary work, e.g. converts input data into the format that tested AD framework needs. `input` parameter is a variable of type `<Objective>Input`. Such classes are defined in the files `<Objective>Data.py` in the folder `/src/python/shared`.
    
    - ```python
      calculate_objective(self, times)
      ```
        Repeatedly calculates objective function given number of times.

    - ```python
      calculate_jacobian(self, times)
      ```
        Repeatedly calculates objective function jacobian given number of times.

    - ```python
      output(self)
      ```
        Returns an object of the class `<Objective>Output` contains calculated values.
        Such classes are defined int the files `<Objective>Data.py`.

4. Do not forget to add your module to the global runner script.

## Unit Tests

For module testing [unittest](https://docs.python.org/3/library/unittest.html) framework is used.

### Adding a new module to common tests
All modules have common tests defined in the folder `/test/python/modules/common`. The file for the specified objective type has the name `<objective>_tests.py`, where `<objective>` is the objective type in the lowercase (e.g. `ba`). If you want to add your module to the module common test list then follow these steps:

1. Open respected common test file.
2. Find a `test_params` variable definition. It looks like this:
    ```python
    # Parameters for different modules. They have the following form:
    # {
    #   "path": <module path relative to src/python/modules directory>,
    #   "tolerance": <tolerance for module output results>
    # }
    test_params = [
        {
            "path": os.path.join("PyTorch", "PyTorchHand.py"),
            "tolerance": 1e-8
        },
        # other class information
    ]
    ```
3. Add information of your objective class to this definition.

### Adding a new common test

If you want to add a new test to common tests, add a new test method to the respected common test class. Method name must start with the `test` prefix and it must not take any parameters except `self`:
```python
def testSomeFeature(self):
  # method body
```
Note, that before any test method running `unittest` framework calls [setUp](https://docs.python.org/3/library/unittest.html#unittest.TestCase.setUp) method of the test class. In the common test classes this method has the following form:
```python
def setUp(self):
    module_path = os.path.join(MODULES_ROOT, self.params["path"])
    self.test = module_load(module_path)
    self.assertIsNotNone(self.test)
```
So, `self.test` variable holds an instance of your objective benchmark class.

You can use standard `unittest` assertion methods or additional assertion methods from the class `TestClassWithAdditionalAsserts`, defined in the file `/test/python/modules/common/utils.py`. This class is extended by common test classes.

### Adding new objective common tests

If you want to add common tests for a new type of objective follow these steps:

1. Add a new python file in the folder `/test/python/modules/common`. It could have any name but suggesting name is `<objective>_tests.py` where  `<objective>` is a name of a new objective type in the lower case.

2. Do any import you need for a new file and also import `unittest` module and `utils.py` file from the folder `/test/python/modules/common`:
    ```python
    import unittest
    import utils
    ```

3. Create a test class inherited form `utils.BaseTestClass`. This base class has additional assertions and also provides parametrization, so, you will able to create common tests for several modules.

5. If you don't need parametrization, then just add the following code to the end of the file:
    ```python
    if __name__ == "__main__":
        unittest.main()
    ```
    If you need parametrization, then you should add something like this:
    ```python
    test_params = [
      # array of test parameters
    ]

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
    ```
    If such a code is added, then `self.params` variable of the test class object will store current test class parameters (respected element of your `test_params` array).

6. You can make a new test file visible for _GTest_ runner. Add the following lines to the file  `/test/python/modules/common/CMakeList.txt`:
    ```CMake
    add_test(NAME <TestsName> COMMAND "<python>" "${CMAKE_SOURCE_DIR}/test/python/modules/common/<test_file_name>")
    ```
    Here `<python>` is the name of your _Python3_ interpreter, `<TestsName>` is the displaying name of your tests for _GTest_, `<test_file_name>` is a name of the new common test file.

### Test Running

You can run test file by a _Python3_ interpreter installed on your machine, e.g.:
```
python3 ba_tests.py
```
All test files that are made visible for _GTest_ can be run using any _GTest_ runner.