# Status

This file contains the current development status of different tools and objectives.

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
- [x] Tapenade

### Python
All Python tools use pip/conda modules. Dependencies for checked items are automatically fetched during CMake configure.
- [x] [Autograd](https://github.com/HIPS/autograd)
- [ ] [Theano](https://github.com/Theano/Theano)
- [x] [PyTorch](https://pytorch.org/)
- [x] [Tensorflow](https://www.tensorflow.org/)

### Matlab
Matlab tools are not currently run by `run-all.ps1` due to the limitations of the Matlab free trial. With the full version, they *should* run correctly.
- [x] [ADiMat](http://www.sc.informatik.tu-darmstadt.de/res/sw/adimat/)
	- Latest release downloaded into folder in /submodules/ (although not a submodule)
- [x] [MuPad](https://www.mathworks.com/discovery/mupad.html)

### F#
- [x] [DiffSharp](https://github.com/DiffSharp/DiffSharp)
	- Built using `dotnet build`, which restores NuGet packages

### Julia
Dependencies for Julia-based tools are listed in `JuliaProject.toml` and automatically fetched during CMake configure.
- [ ] ForwardDiff.jl
- [x] Zygote


## Completeness

This is a table of all current tools, with their status in terms of running each of the current objectives. See below for more details about specific issues.

| Tool      | GMM   | BA    | Hand  | LSTM  |
| --------- | ----- | ----- | ----- | ----- |
| Adept     |   x   |   x   |   x   |   -   |
| ADiMat	|   x   |   !   |   x   |   -   |
| ADOLC     |   x   |   x   |   x   |   -   |
| Autograd  |   x   |   x   |   *   |   -   |
| Ceres     |   x   |   x   |   *   |   -   |
| DiffSharp |   x!  |   x   |   x   |   x   |
| Finite    |   x   |   x   |   x   |   x   |
| Julia     |   x   |   x   |   -   |   -   |
| Manual    |   x   |   x   |   x   |   x   |
| MuPad     |   x   |   !   |   ?   |   -   |
| PyTorch   |   x   |   x   |   x   |   x   |
| Tapenade  |   x   |   x   |   x   |   x   |
| Tensorflow|   x   |   x   |   x   |   x   |
| Theano    |   x   |   x   |   x   |   -   |
| Zygote    |   x!  |   x   |   x   |   x   |

### Key
- `x` = Runs successfully
- `x!` = Generally runs successfully, but fails on some of the problem sizes
- `!` = Has been attempted, with problems
- `?` = Has been started, but is not complete
- `-` = Not attempted yet
- `*` = Not possible/no intention of doing
