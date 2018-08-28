# Issues

This is a list of known issues/TODOs for the project. Any fixes are welcomed.

## ADBench

- `plot_graphs.py` - integrate the old 3D graph code into the new graphing structure

## Tools

- Test building and running on non-windows platforms
    - Will need to produce alternatives to existing batch files (currently in ADOL-C, DiffSharp, MuPad, Theano)
- ADiMat
    - `ADiMat_ba.m` - test seems to crash during Jacobian loop
- ADOLC
    - `build.bat`
        - Remove hard paths to `vcvarsall.bat`
        - Try to automate Windows SDK selection, and/or check properly for correct SDK and give clear error message
    - `main.cpp` - build fails with `DO_BA_BLOCK` and `DO_EIGEN`
- Ceres
    - Memory issue when building GMM at instance sizes above about d=20,K=50
- DiffSharp
    - GMM build fails (expected float[] but got D[])
- Manual
    - `ba_d.cpp` - refactor functions under `DO_CPP` to work without Eigen
    - Perhaps add Hand derivative without Eigen
- Theano
    - `run.bat` - remove hard path to Miniconda

## Accuracy

See [ADBench/J_Errors.txt](/ADBench/J_Errors.txt) for the output of ADBench/check_J.py, which shows a list of mismatches among output (jacobian) text files.
