# Building and Running

## With Docker

If you want to only run the benchmarks, instead of installing all the [prerequisites](#prerequisites), you can just install docker.

To run benchmarks in a docker container, follow the guide [here](./Docker.md).

## Without Docker

### Prerequisites

- [CMake 3.12+](https://cmake.org/)
- A compatible build system and C++ compiler (e.g. MSBuild and MSVC++ on Windows, Make and GCC on Linux)
- [.NET Core 2.1 SDK](https://dotnet.microsoft.com/download/dotnet-core/2.1)
- [Python 3](https://www.python.org/)
    
    Pip and setuptools must be installed and upgraded:
    ```bash
    python -m pip install --upgrade pip
    python -m pip install pip setuptools>=41.0.0
    ```
- [Julia 1.2+](https://julialang.org/)
- [PowerShell or PowerShell Core](https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-powershell)

Binaries for the above must be available on PATH.

All the dependencies not mentioned here will be fetched automatically during CMake configuration and building.

### Build and Test

#### With Visual Studio 2017/2019 (Windows only)

Make sure, your Visual Studio installation includes CMake tools for Visual Studio. If that is not the case, you can install it as a component in the [Visual Studio Installer](https://docs.microsoft.com/en-us/visualstudio/install/install-visual-studio).

Now, just open the folder with the cloned repository in Visual Studio. CMake should run automatically. The repository already contains a sensible `CMakeSettings.json` file, so you should be able to choose between debug and release configurations.

When Visual Studio will finish building CMake cache, you should be able to build ADBench with Visual Studio's "Build All" command.

After the build was succeeded, unit tests should become available in the test explorer as usual.

#### With Visual Studio Code (Windows and Linux)

Open the folder with the cloned repository in Visual Studio Code. The repository contains a `.vscode/extensions.json` file with a list of recommended extensions, so VS Code should prompt you to install them. Agree.

When you open the folder repository in VS Code with all the recommended extensions, it should automatically prompt you to perform CMake configuration, after which buttons for selecting build configuration, building all targets, and running unit tests should appear on the VS Code's bottom bar.

#### Python Environments

The build scripts will install dependencies using pip. We recommend using a virtual environment tool such as [venv](https://docs.python.org/3/library/venv.html) to create a separate environment before running the scripts.

#### From Command Line (Windows and Linux)

To build in `my-build` subfolder of the folder with the cloned repository:

```bash
cd [directory with the cloned repository]
mkdir my-build
cd my-build
cmake -DCMAKE_BUILD_TYPE=<Debug|RelWithDebInfo|Release> ..
cmake --build .
```

To build in another folder modify accordingly.

To run unit tests just execute `ctest` in the folder with binaries.

### Run

You can run the benchmarks with the `ADBench/run-all.ps1` PowerShell script.
See [GlobalRunner.md](./GlobalRunner.md) for details.
