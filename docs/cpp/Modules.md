# C++ Modules

## Adding new modules
1. Create a `CMakeLists.txt` file in the `/src/cpp/modules/yourModule` directory with the following content where `YourModule` is the name of your module:
    ```cmake
    project("ADBench_YourModule" CXX)

    add_library("YourModule" MODULE)
    ```
    
    Note that [run-all.ps1 script](../Architecture.md#global-runner) expects directory name to be equal to module binary name but with a lowercase first letter.
2. Open `/src/cpp/modules/CMakeLists.txt` and add the next string: 
    ```cmake
    add_subdirectory ("YourModule")
    ```
3. <span id="itest-implementation"> For each objective create a class implementing `ITest<TInput,TOuput>` interface where `T` is an objective type (GMM, BA etc.). You can find this interface in the file `../../shared/ITest.h` (the path is relative to the directory of your module). `*TInput*` and `*TOutput*` are input and output types specific for the objective there. They are defined in the file `../../shared/TData.h` (the path is relative to the directory of your module).
    
    The functions you need to implement:
    - ```cpp
      virtual void prepare(TInput&& input)
      ```
        Converts the input data from the format in which it is provided by the calling benchmark runner into the format optimized for use with the tested AD framework. It also allocates memory for internal buffers and results structure.
    - ```cpp 
      virtual void calculate_objective(int times)
      ``` 
        Repeatedly computes one of the objective functions given number of times, saving results into a pre-allocated internal structure.
    - ```cpp
      virtual void calculate_jacobian(int times)
      ```
        Repeatedly computes a derivative of one of the objective functions given number of times, saving results into a pre-allocated internal structure.
    - ```cpp
      virtual TOutput output()
      ```
        Convertes internally saved outputs into the format specified by the runner.
    </span>

4. For each class add an exported factory function just below class implementation as follows:
    ```cpp
    extern "C" DLL_PUBLIC ITest<TInput, TOutput>* get_T_test()
    {
        return new YourClass();
    }
    ```
    where `T` is still an objective type here.

    `DLL_PUBLIC` is a macro defined in `/src/shared/ITest.h`. It is made to export functions from shared libraries both on Windows and Linux with GCC and MSVC compilers.
5. Specify target sources in the project `CMakeLists.txt` file.
6. Compile, run via C++ runner and enjoy!

Please, don't forget to add unit tests.

## Unit Tests

GTest and GMock frameworks are used to test C++ modules in this project.

### Adding tests for a new module

AD Bench already contains some tests for each objective.
When you add a new module, first thing you should do is to test your module with the existing tests.

Follow the next steps for every objective you want to test:

1. Open `/test/cpp/modules/common/TTests.cpp` where `T` is the short name of the testing objective.
    
   You will see the next lines:
    ```cpp
    INSTANTIATE_TEST_CASE_P(T, TModuleTest,
    ::testing::Values(
        "../../../../src/cpp/modules/manual/Manual.dll",
        "../../../../src/cpp/modules/manualEigen/ManualEigen.dll",
            ...
    ),
    get_module_name<ModuleTest::ParamType>);
    ```
2. Add module's path to the list of testing modules like this:
    ```cpp
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

1. Open `/test/cpp/modules/common/TTests.cpp` where `T` is the short name of the testing objective.
2. Add the next lines to the end of the file:
    ```cpp
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

You might want to add a new type of objective to test. In that case just do the next things:

1. In the `/test/cpp/modules/common/` directory create a `TTests.cpp` file.
2. Include `gtest/gtest.h` in your file.
3. Use `INSTANTIATE_TEST_CASE_P` macro to list all modules supporting `T` objective type as it described in the ["Adding tests for a new module"](#adding-tests-for-a-new-module) section.
4. Use `TEST_P` macro to add new test cases as it described in the ["Adding a new test case"](#adding-a-new-test-case) section.
5. Open `/test/cpp/modules/common/CMakeLists.txt` and mark `TTests.cpp` file as source via `target_sources` command there.

