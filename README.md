# ADBench - autodiff benchmarks

## Aim

To provide a comparison for different tools for automatic differentiation.

## Usage

All tools should build (along with any external packages) and run very easily.

1) Clone the repository
2) Run cmake
3) Build
4) Run ADBench/run-all.ps1

In order to run Python tools, the following packages are required (just `pip install` each of them):

- numpy
- scipy
- matplotlib
- autograd
- Theano

## Tools

Checked items are built by CMake and run by run-all.ps1

### C++
- [x] [Adept](https://github.com/rjhogan/Adept-2)
- [x] [ADOLC](https://gitlab.com/adol-c/adol-c)
- [x] [Ceres](https://github.com/ceres-solver/ceres-solver)
- [x] Manual AD
- [ ] Tapenade

### Python
- [ ] [Autograd](https://github.com/HIPS/autograd)
- [ ] [Theano](https://github.com/Theano/Theano)

### Matlab
- [ ] ADiMat
- [ ] [MuPad](https://www.mathworks.com/discovery/mupad.html)

### F#
- [ ] [DiffSharp](https://github.com/DiffSharp/DiffSharp)

### Julia
- [ ] Julia AD

## Folder structure:

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

## Issues
- Only tested on Windows (64-bit)
	- Should mostly work on other platforms, but ADOL-C may not build properly
