# Development

This document provides some high-level guidelines on how to work with the ADBench codebase.

## Setting Up the Development Environment

Due to its nature, ADBench spans over many different technologies and programming languages. While the codebase can be edited with any text editor and built from command line, there's a bit of special support in form of checked in configurations for Visual Studio and Visual Studio Code.

The requirements for development environment and for build environment are the same, so please, refer to the ["without Docker"](./BuildAndTest.md#without-docker) of the building guide for details.

## Architecture

See [Architecture.md](./Architecture.md).

## Structure of the Repository

- `.vscode` - configuration files for VS Code workspace.
- `ADBench/` - scripts for running benchmarks and plotting results.
- `adobuilds/` - build definitions to use with Azure DevOps.
- `data/` - inputs for benchmarks.
- `docs/` - documentation.
- `Documents/` - papers, presentations, etc.
- `etc/` - [HunterGate](https://github.com/ruslo/hunter) files.
- `src/` - source code for benchmark runners and testing modules.
    - `cpp/` - C++ runner and modules.
        - `modules/` - C++ testing modules (in corresponding subfolders).
        - `runner/` - C++ benchmark runner.
        - `shared/` - C++ source code shared by runner and different modules.
        - `utils/` - other utilities in C++.
            - `finitePartialGmm` - console app that computes parts of GMM gradient using finite differences. Used in the process of verifying the `Manual` module, see [Verification of the Golden Module](./JacobianCheck.md#verification-of-the-golden-module) for details.
        - `CMakeLists.txt`
    - `dotnet/` - .NET Core runner and modules. Follows the same structure as `cpp`.
    - `julia/` - Julia runner and modules. Follows the same structure as `cpp`.
    - `python/` - Python runner and modules. Follows the same structure as `cpp`.
    - `CMakeLists.txt`
- `submodules/` - dependencies fetched as git submodules.
- `test/` - unit tests for benchmark runners and testing modules.
    - `cpp/` - tests for C++ runner and modules.
        - `modules/` - unit tests for C++ testing modules.
            - `common` - parametrized test suites shared by different testing modules
            - `CMakeLists.txt`
        - `runner/` - unit tests for C++ benchmark runner.
        - `CMakeLists.txt`
    - `dotnet/` - unit tests for .NET Core runner and modules. Follows the same structure as `cpp`.
    - `julia/` - unit tests for Julia runner and modules. Follows the same structure as `cpp`.
    - `python/` - unit tests for Python runner and modules. Follows the same structure as `cpp`.
    - `CMakeLists.txt`
- `tmp/` - benchmark results, plots
- `tools/` - source code for benchmarks that don't yet follow the [architecture](./Architecture.md).
- `CMakeLists.txt`
- `CMakeSettings.json` - settings for Visual Studio CMake tools
- `Dockerfile`
- `JuliaManifest.toml`, `JuliaProject.toml` - description of workspace for Julia components

## Build Process

CMake is used here to build all the compiled code, fetch the dependencies of both compiled and interpreted code, and run all the unit tests. It is also used to prepare some of the variables of the [global runner](./GlobalRunner.md) script. Because of that you may, sometimes, encounter `CMakeLists.txt` files in unexpected places, such as a folder with python source code, where it fetches dependencies during CMake configuration, a folder with C# code where it adds a custom build step that invokes `dotnet`, or a folder with tests in Julia where it defines a test for CTest.

Uses of CMake on non-C/C++ codebases are usually documented along with corresponding codebases. The general rule is that after running CMake configure and CMake build the [global runner](./GlobalRunner.md) should work correctly, and running CTest should execute all existing unit tests.

## Adding New Components

### Testing Modules

If you want to add a testing module for one of the existing benchmark runners, then, please, refer to the corresponding documentation:

- [C++](cpp/Modules.md)
- [.NET Core](dotnet/Modules.md)
- [Julia](julia/Modules.md)
- [Python](python/Modules.md)

Otherwise, you'll need to implement a benchmark runner for your module first.

### Benchmark Runners

The description of what benchmark runners are and what they should do can be found [here](./Architecture.md#benchmark-runners). Probably, the easiest way to implement one is to translate one of the existing benchmark runners into the language you need. The part that dynamically loads plugins will obviously need adaptation to your target platform, though.

When looking for where to place your new code, follow the patterns established for other platforms (e.g. sources in `src/<platform>/**`, tests in `test/<platform>/**`, etc.).

Write `CMakeLists.txt` files, so that all your dependencies are fetched when necessary, your compiled code is built when CMake build is invoked, and your unit tests is executed by CTest with all other unit tests. Writing documentation similar to that for the existing runners would also be very appreciated.

Make the [global runner](./GlobalRunner.md) be able to work with your benchmark runner. See the [corresponding section](./GlobalRunner.md#interfacing-with-benchmark-runners) of its documentation for details on how to do that.

### Objective Functions

To add a new objective functions, start by adding its support to benchmark runners. For details, see the corresponding documentation for each runner:
- [C++](cpp/Runner.md#adding-new-objective-types)
- [.NET Core](dotnet/Runner.md#adding-new-objective-types)
- [Julia](julia/Runner.md#adding-new-objective-types)
- [Python](python/Runner.md#adding-new-objective-types)

After that add the support for your new objective functions to all testing modules you want to benchmark with it.

Put inputs for your new objective function into the corresponding subfolder of `data` folder.

Finally, add it to `run-all.ps1`:
1. Add the name of your objective to the `ObjectiveType` enumeration.
1. Add a new method to the `[Tool]` class (format should be `[Tool]::test<your objective name>()`)
1. Add this to `[Tool]::runall()`
1. Modify the `$objectives` parameter for each of the `[Tool]` constructors in the `tool_descriptors` array by adding the name of your objective to the objective lists as necessary

### Result-processing Scripts

Just add them. They are in the end of the tool chain, so no special considerations there.