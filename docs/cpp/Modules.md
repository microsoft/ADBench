


# C++ Modules

## Adding new modules
1. Create a CMakeLists.txt file in the /src/cpp/modules/yourModule directory with the following content where "YourModule" is the name of your module:
    ```
    project("ADBench_YourModule" CXX)

    add_library("YourModule" MODULE)
    ```
    
    Note that [run-all.ps1 script](../Architecture.md#global-runner) expects directory name to be equal to module binary name but with a lowercase first letter.
2. Open /src/cpp/modules/CMakeLists.txt and add the next string: 
    ```
    add_subdirectory ("YourModule")
    ```
3. <span id="itest-implementation"> For each objective create a class implementing ITest<TInput,TOuput> interface where T is an objective type (GMM, BA etc.). *TInput* and *TOutput* are input and output types specific for the objective. They are defined in the file "../../shared/TData.h" (the path is relative to the directory of your module).
    - virtual void prepare(TInput&& input) - converts the input data from the format in which it is provided by the calling benchmark runner into the format optimized for use with the tested AD framework. It also allocates memory for internal buffers and results structure.
    - virtual void calculate_objective(int times) - repeatedly computes one of the objective functions given number of times, saving results into a pre-allocated internal structure.
    - virtual void calculate_jacobian(int times) - repeatedly computing a derivative of one of the objective functions given number of times, saving results into a pre-allocated internal structure.
    - virtual TOutput output() - convertes internally saved outputs into the format specified by the runner.
    </span>

4. For each class add an exported factory function just below class implementation as follows:
    ```
    extern "C" DLL_PUBLIC ITest<TInput, TOutput>* get_T_test()
    {
        return new YourClass();
    }
    ```
    where T is still an objective type here.

    DLL_PUBLIC is a macro defined in /src/shared/ITest.h. It is made to export functions from shared libraries both on Windows and Linux with GCC and MSVC compilers.
5. Specify target sources in the project CMakeLists.txt file.
6. Compile, run via C++ runner and enjoy!

Please, don't forget to add unit tests.

## Unit Tests

GTest and GMock frameworks are used to test C++ modules in this project.

### Adding tests for a new module

AD Bench already contains some tests for each objective.
When you add a new module, first thing you should do is testing your module with the existing tests.

Follow the next steps for every objective you want to test:

1. Open "/test/cpp/modules/common/TTests.cpp" where T is the short name of the testing objective.
    
   You will see the next lines:
    ```
    INSTANTIATE_TEST_CASE_P(T, TModuleTest,
    ::testing::Values(
        "../../../../src/cpp/modules/manual/Manual.dll",
        "../../../../src/cpp/modules/manualEigen/ManualEigen.dll",
            ...
    ),
    get_module_name<ModuleTest::ParamType>);
    ```
2. Add module's path to the list of testing modules like this:
    ```
    INSTANTIATE_TEST_CASE_P(T, TModuleTest,
    ::testing::Values(
        "../../../../src/cpp/modules/manual/Manual.dll",
        "../../../../src/cpp/modules/manualEigen/ManualEigen.dll",
            ...
        your_path
    ),
    get_module_name<ModuleTest::ParamType>);
    ```

### Adding a new test case

Follow the next steps to add a new test case for objective:

1. Open "/test/cpp/modules/common/TTests.cpp" where T is the short name of the testing objective.
2. Add the next lines to the end of the file:
    ```
    TEST_P(TModuleTest, TestCaseName)
    {
        ...
        test_code
        ...
    }
    ```

    In a test case you should generally:
    1. load the module
    2. load input data
    3. prepare the module
    4. perform computations
    5. compare the results of computations with the previously known correct ones

### Adding new objectives

