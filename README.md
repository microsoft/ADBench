# ADBench - autodiff benchmarks

## Aim

To provide a running-time comparison for different tools for automatic differentiation, 
as described in https://arxiv.org/abs/1807.10129, (source in Documentaion/ms.tex).

Output a set of relevant graphs.

## Prerequisites

- CMake
- .NET
- FSharp
- Python (with the following `pip` modules)
	- numpy
	- scipy
	- matplotlib
	- autograd
- [Miniconda](https://conda.io/miniconda.html) (only required to run Theano)
	- Once installed, open the Anaconda Prompt as an administrator and run:
	- `conda install numpy scipy mkl-service libpython m2w64-toolchain`
	- `conda install theano pygpu`
- Powershell (default on Windows)

## Installation/Usage

All tools should build (along with any external packages) and run very easily.

1) Clone the repository (make sure submodules are cloned properly)
2) Run cmake
3) Build
4) Run `powershell ADBench/run-all.ps1`
5) Run `python ADBench/plot_graphs.py`

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

