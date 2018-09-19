# Status

This file contains details about the layout of the repository, and the current development status of different tools and objectives.


## Folder structure

| Folder    | Purpose
| --------- | ------- |
| ADBench   | Orchestration scripts, plotting etc
| Backup	| Old files
| Documents | Graphs, papers, presentations etc
| bak		| Old files
| data      | Data files for different examples 
| etc		| [HunterGate](https://github.com/ruslo/hunter) files
| submodules| Dependencies on other git repositories
| tmp       | Output of benchmark files, figures etc
| tools     | Implementations for each tested tool, one folder per tool, with *-common folders for shared files by language
| usr       | Per-user scratch folder


## Tools

Checked items are built (where relevant) by CMake and can be run by run-all.ps1

### C++
- [x] [Adept](https://github.com/rjhogan/Adept-2)
	- Git submodule
	- Built using custom CMake
- [x] [ADOLC](https://gitlab.com/adol-c/adol-c)
	- Git submodule
	- Built using a batch file (to run `msbuild`) on windows
- [x] [Ceres](https://github.com/ceres-solver/ceres-solver)
	- HunterGate packages
	- Built with shared libs
	- For GMM, relies on `#define` for d and k values, so multiple executables are built
- [x] Finite
	- Computes numeric derivatives (finite differences) for comparison
	- No external dependencies
- [x] Manual
	- Manually-differentiated C++ functions
	- No external dependencies
- [ ] Tapenade

### Python
All Python tools use pip/conda modules. See list under [Prerequisites](#prerequisites).
- [x] [Autograd](https://github.com/HIPS/autograd)
- [x] [Theano](https://github.com/Theano/Theano)
- [x] [PyTorch](https://pytorch.org/)

### Matlab
Matlab tools are not currently run by `run-all.ps1` due to the limitations of the Matlab free trial. With the full version, they *should* run correctly.
- [x] [ADiMat](http://www.sc.informatik.tu-darmstadt.de/res/sw/adimat/)
	- Latest release downloaded into folder in /submodules/ (although not a submodule)
- [x] [MuPad](https://www.mathworks.com/discovery/mupad.html)

### F#
- [x] [DiffSharp](https://github.com/DiffSharp/DiffSharp)
	- Built using `dotnet build` (in batch file), which restores NuGet packages

### Julia
- [ ] ForwardDiff.jl


## Completeness

This is a table of all current tools, with their status in terms of running each of the current objectives. See below for more details about specific issues.

| Tool      | GMM   | BA    | Hand  | LSTM  |
| --------- | ----- | ----- | ----- | ----- |
| Adept     |   x   |   x   |   x   |   -   |
| ADiMat	|   x   |   !   |   x   |   -   |
| ADOLC     |   x   |   x   |   x   |   -   |
| Autograd  |   x   |   x   |   *   |   -   |
| Ceres     |   x   |   x   |   *   |   -   |
| DiffSharp |   !   |   x   |   -   |   -   |
| Finite    |   x   |   x   |   x   |   x   |
| Julia     |   -   |   -   |   -   |   -   |
| Manual    |   x   |   x   |   x   |   ?   |
| MuPad     |   x   |   !   |   ?   |   -   |
| PyTorch   |   x   |   !   |   x   |   x   |
| Tapenade  |   -   |   -   |   -   |   -   |
| Theano    |   x   |   x   |   x   |   -   |

### Key
- `x` = Runs successfully
- `!` = Has been attempted, with problems
- `?` = Has been started, but is not complete
- `-` = Not attempted yet
- `*` = Not possible/no intention of doing
