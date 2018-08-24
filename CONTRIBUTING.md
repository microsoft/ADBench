# Contributing

Here, 'tool' refers to an Automatic Differentiation tool to be benchmarked, and 'test' (or 'objective') refers to a function being tested.

## Adding new tools

1. Create a folder in `/tools` for your tool
2. Add the tool as a dependency. There are various way to do this (listed in descending order of preference):
    - If using a Python module, add it to the list of `pip` (or `conda` if necessary) requirements in [README.md](/README.md)
    - If available as a [Hunter package](https://docs.hunter.sh/en/latest/packages.html), add that in the relevant CMakeLists.txt file
    - If available through `git`, add it as a submodule in `/submodules`
    - If available through NuGet, build your tool using `dotnet` and add it as a dependency (see DiffSharp as an example of this)
3. Add the tool, with objectives
    - `{tool name}` should match the name of the folder you have created
    - `{test name}` should include additional details such as `GMM-FULL` or `Hand-Eigen-simple`. See the existing tools as examples to ensure this is done correctly.
    - For compiled languages:
        - Create a main/program file as the entry-point for all tests
        - If appropriate, create separate files with functions for each test
        - Create a `CMakeLists.txt` file in your folder. If in a language which CMake builds, add it to the CMake build list here. If not, tell CMake to run any necessary build scripts using `execute_process`.
        - Executables should be built (in `${CMAKE_CURRENT_BINARY_DIR}`) for each test (i.e. using different `#defines`). They should be named in the format `Tools-{tool name (as in the folder name)}-{test name (uppercase)}.{ext}`
        - Add your folder as a subdirectory in `/tools/CMakeLists.txt`
    - For interpreted languages:
        - There should be a script for each test to run
        - Scripts should be named in the format `'{tool name (as in the folder name)}_{test name (lowercase)}.{ext}'`
        - For examples, see the Python and Matlab tools
4. Add to `run-all.ps1`
    - Add it to the `$tools` array using the `[Tool]` class
5. Run tests on your tool and re-generate graphs

## Adding new tests

1. Add the test to all tools where possible
2. Add the test to `run-all.ps1`
    1. Create a new method on the `[Tool]` class (format should be `[Tool]::test{your test name}()`)
    2. Add this to `[Tool]::runall()`
    3. Modify the `$objectives` parameter for each of the `[Tool]` constructors
        - Append a `1` for any tools for which the test is implemented
        - Append a `0` where the test is not yet implemented
3. Run your test and generate graphs for it
