# ADBench - autodiff benchmarks

This project aims to provide a running-time comparison for different tools for automatic differentiation, 
as described in https://arxiv.org/abs/1807.10129, (source in [Documentation/ms.tex](Documentation/ms.tex)).
It outputs a set of relevant graphs (see [Example Graphs](#Example%20Graphs)).

For information about the layout and status of the project, see [Status](STATUS.md).

## Prerequisites

- [CMake](https://cmake.org/) (see [Installation](#installation) for details)
- [.NET](https://www.microsoft.com/net) (should be in PATH)
- [FSharp](https://fsharp.org/)
- [Matlab](https://www.mathworks.com/products/matlab.html) (in PATH)
	- **Note:** while the free trial version works, the obtrusive login dialog makes it impossible to automatically run all matlab tests without manually logging in each time
- [Python](https://www.python.org/) (in PATH), with the following `pip` modules:
	- numpy
	- scipy
	- matplotlib
	- plotly
	- autograd
	- PyTorch (install from [here](https://pytorch.org/))
- [Miniconda](https://conda.io/miniconda.html) (only required to run Theano)
	- Once installed, open the Anaconda Prompt as an administrator and run:
	- `conda install numpy scipy mkl-service libpython m2w64-toolchain`
	- `conda install theano pygpu`
- [Powershell](https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-powershell
) (default on Windows)

## Installation

All tools should build (along with any external packages) and run very easily, provided you are able to use CMake. CMake should always work similarly, but the easiest methods may vary by operating system.

The basic steps (more specific instructions for Windows are below):

1) Clone the repository (make sure submodules are cloned properly)
2) Optional: set HUNTER_ROOT environment variable to choose where HunterGate pacakges are stored.  If not set, will default to etc/HunterGate-Root.
3) Run cmake
	- mkdir my-build  # Directories with name *-build/ are ignored in .gitignore
	- cd my-build
	- cmake ..
	- If you get an error of the form "The input line is too long.  The syntax of the command is incorrect.", your $ENV:PATH may be too long (!)

3) Build

### Windows

The easiest way to build on windows is using [CMake tools for Visual Studio](https://blogs.msdn.microsoft.com/vcblog/2016/10/05/cmake-support-in-visual-studio/), which can be installed as a component in the [Visual Studio Installer](https://docs.microsoft.com/en-us/visualstudio/install/install-visual-studio).

1) Open Visual Studio
2) [Clone](http://www.malgreve.net/2014/06/17/cloning-getting-code-from-git-repository-to-visual-studio/) this repository
3) Open the cloned folder in Visual Studio. CMake should run automatically, but it may need to be started manually.
	- **NOTE:** CMake (specifically HunterGate) often seems to crash the first time it is run, so try re-running several times.
	- **NOTE:** HunterGate requires that the path to the folder does not contain spaces. This can be disabled but is not currently.
4) When CMake has finished, run CMake>Build All
	- **NOTE:** this is sometimes not available as an option. Try restarting Visual Studio or waiting a while.

All tools should now be built. See [Usage](#usage) below.

#### Windows from the command line

Instead of using Visual Studio you can execute the following command

```
cmake -G "Ninja" '-DCMAKE_TOOLCHAIN_FILE=<path-to-top-level>\toolchain.cmake' '-DCMAKE_BUILD_TYPE="RelWithDebInfo"' "<path-to-top-level>"
ninja
```

You have to somehow ensure that `cmake`, `cl` and `ninja` are on your
path.

## Usage

1) Run `powershell ADBench/run-all.ps1` to run all of the tools and write the timings to `/tmp/`.
2) Run `python ADBench/plot_graphs.py` to plot graphs of the resulting timings and write them to `/Documents/New Figures/`

### CLI reference: run-all

`powershell ADBench/run-all.ps1 buildtype nruns_f nruns_J time_limit tmpdir repeat`
- `buildtype`: The build configuration of the tests to be run (`Debug` or `Release`). By default, both will be run (pass an empty string `""` to replicate this).
- `nruns_f`: Number of times to run the original functions (BA, GMM) for each tool (default = `10`)
- `nruns_J`: Number of times to run the autodiff process for each tool (default = `10`)
- `time_limit`: The maximum amount of time (in seconds) to spend benchmarking each tool (default = `60`)
	- After each run, the program will check if it has exceeded the time limit
	- `time_limit` will never cause a task to run less than once, and the program will always output a resultant time
	- **Note**: The time limits are only implemented in C++ and Python currently
- `timeout`: The maximum amount of time (in seconds) to allow each tool to run for
	- If a program exceeds this time limit, PowerShell kills it
	- This may result in no runs being completed, and no output being produced (PowerShell will output a file with `inf` timings in it to mark the test as failed)
- `tmpdir`: The output directory to use (default = `/tmp/`)
- `repeat`: Whether to repeat tasks for which an output file already exists (default = `false`)

### CLI reference: plot_graphs

`python plot_graphs.py [--save] [--plotly] [--show]`
- `--save`: Save graphs as .png files to `Documents/New Figures/`
- `--plotly`: Save graphs as [Plot.ly](https://plot.ly/) .html files to `Documents/New Figures/plotly/`
- `--show`: Display graphs in new windows
- If neither `--save` or `--plotly` are included, `--show` will be `True` by default - otherwise, it must be manually enabled

### check_J

`python check_J.py`
- This script compares all available Jacobian output files, and outputs results to the console
- It will flag missing output files, and indicate where there may be a mismatch between files
- For comparison, all derivatives are rounded to a certain number of significant figures, as specified by a constant at the top of the script

## Contributing

Contributions to fix bugs, test on new systems or add new tools are welcomed. See [Contributing](/CONTRIBUTING.md) for details on how to add new tools, and [Issues](/ISSUES.md) for known bugs and TODOs.

## Known Issues

See [Issues](/ISSUES.md) for a complete list of known problems and TODOs.

## Example Graphs

Below are two examples of the graphs produced by ADBench/plot_graphs.py. The full range of graphs (over 40) can be found in both static (png) and [Plot.ly](https://plot.ly/) (html) formats in [Documents/New Figures](/Documents/New%20Figures/).

![GMM 1k Jacobian Release Graph](/Documents/New%20Figures/static/Release/jacobian/GMM%20%281k%29%20[Jacobian]%20-%20Release%20Graph.png)

![Hand Simple Small Jacobian÷Objective Debug Graph](/Documents/New%20Figures/static/Debug/jacobian%20÷%20objective/HAND%20%28Simple,%20Small%29%20[Jacobian%20÷%20objective]%20-%20Debug%20Graph.png)
