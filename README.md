# ADBench - autodiff benchmarks

## Aim

To provide a running-time comparison for different tools for automatic differentiation, 
as described in https://arxiv.org/abs/1807.10129, (source in Documentaion/ms.tex).

Output a set of relevant graphs.

## Prerequisites

- [CMake](https://cmake.org/)
- [.NET](https://www.microsoft.com/net)
- [FSharp](https://fsharp.org/)
- [Matlab](https://www.mathworks.com/products/matlab.html)
	- **Note:** while the free trial version works, the obtrusive login dialog makes it impossible to automatically run all matlab tests without manually logging in each time
- [Python](https://www.python.org/) (with the following `pip` modules)
	- numpy
	- scipy
	- matplotlib
	- plotly
	- autograd
- [Miniconda](https://conda.io/miniconda.html) (only required to run Theano)
	- Once installed, open the Anaconda Prompt as an administrator and run:
	- `conda install numpy scipy mkl-service libpython m2w64-toolchain`
	- `conda install theano pygpu`
- [Powershell](https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-powershell
) (default on Windows)

## Installation/Usage

All tools should build (along with any external packages) and run very easily.

1) Clone the repository (make sure submodules are cloned properly)
2) Run cmake
3) Build
4) Run `powershell ADBench/run-all.ps1`
5) Run `python ADBench/plot_graphs.py`

### CLI reference: run-all

`powershell ADBench/run-all.ps1 nruns_f nruns_J time_limit tmpdir repeat`
- `nruns_f`: Number of times to run the original functions (BA, GMM) for each tool (default = `10`)
- `nruns_J`: Number of times to run the autodiff process for each tool (default = `10`)
- `time_limit`: The maximum amount of time (in seconds) to spend benchmarking each tool (default = `60`)
	- **Note**: A whole number of runs (and at least one) will always be completed
	- **Note**: The time limits are only implemented in C++ and Python currently
- `tmpdir`: The output directory to use (default = `tmp`)
- `repeat`: Whether to repeat tasks for which an output file already exists (default = `false`)

### CLI reference: plot_graphs

`python plot_graphs.py [--save] [--plotly]`
- With no switch, graphs are displayed in new windows
- `--save`: Save graphs as .png files to `Documents/New Figures/`
- `--plotly`: Save graphs as [Plot.ly](https://plot.ly/) .html files to `Documents/New Figures/plotly/`
**Note**: The `--save` and `--plotly` switches cannot be used simultaneously due to a bug (in either matplotlib or plotly)

## Folder structure

| Folder    | Purpose
| --------- | ------- |
| ADBench   | Orchestration scripts, plotting etc
| Backup	| Old files
| Documents | Papers, presentations etc
| bak		| Old files
| data      | Data files for different examples 
| etc		| [HunterGate](https://github.com/ruslo/hunter) files
| submodules| Dependencies on other git repositories
| tmp       | Output of benchmark files, figures etc
| tools     | Implementations for each tested tool, one folder per tool, with *-common folders for shared files by language
| usr       | Per-user scratch folder

## Tools

Checked items are built by CMake and can be run by run-all.ps1

### C++
- [x] [Adept](https://github.com/rjhogan/Adept-2)
	- Git submodule
	- Built using custom cmake
- [x] [ADOLC](https://gitlab.com/adol-c/adol-c)
	- Git submodule
	- Built using a batch file (to run `msbuild`) on windows
- [x] [Ceres](https://github.com/ceres-solver/ceres-solver)
	- HunterGate packages
	- Built with shared libs
	- For GMM, relies on `#define` for d and k values, so multiple executables are built
- [x] Manual AD
	- No external dependencies
- [ ] Tapenade

### Python
- [x] [Autograd](https://github.com/HIPS/autograd)
- [x] [Theano](https://github.com/Theano/Theano)

### Matlab
- [ ] ADiMat
- [ ] [MuPad](https://www.mathworks.com/discovery/mupad.html)

### F#
- [x] [DiffSharp](https://github.com/DiffSharp/DiffSharp)
	- Built using `dotnet build` (in batch file), which restores NuGet packages
	- GMM builds fail

### Julia
- [ ] Julia AD

## Known Issues
- Only tested on Windows (64-bit)
	- Should mostly work on other platforms, but ADOL-C may not build properly
	- Hard-coded paths (which may be wrong on some systems) in batch files (for ADOL-C, DiffSharp and Theano)
- Ceres only builds up to certain d (20) and k (50) values, due to memory issue
	- Should be solvable, but needs looking into
- DiffSharp GMM builds fail
- run-all.ps1 does not currently run all tools

## Example Graphs

### Debug

<div>
	<img src="/Documents/New%20Figures/BA%20(Debug)%20Graph.png" width="49%" />
	<img src="/Documents/New%20Figures/GMM%20(Debug)%20Graph.png" width="49%" />
</div>

### Release

<div>
	<img src="/Documents/New%20Figures/BA%20(Release)%20Graph.png" width="49%" />
	<img src="/Documents/New%20Figures/GMM%20(Release)%20Graph.png" width="49%" />
</div>

