# Issues

This is a list of known issues/TODOs for the project. Any fixes are welcomed.


## ADBench

- `plot_graphs.py` - integrate the old 3D graph code into the new graphing structure


## Documents

- The existing graphs are not ideal:
    - Not enough time has been allocated, so many tools have "timed out" (when they should have been given more time)
    - These timeouts have not been consistent across tools
    - Tools have been run at different times, and often the computer used was doing something else simultaneously
    - Have not run with large data sizes yet due to time constraint


## Tools

- Test building and running on non-windows platforms
    - Will need to produce alternatives to existing batch files (currently in ADOL-C, MuPad, Theano)
- Matlab tools need testing properly
    - `run-all.ps1` has Matlab tools commented out by default.  If Matlab is available on your system, uncomment.
- ADiMat
    - `ADiMat_ba.m` - test seems to crash during Jacobian loop
- ADOLC
    - `build.bat`
        - Remove hard paths to `vcvarsall.bat`
        - Try to automate Windows SDK selection, and/or check properly for correct SDK and give clear error message
    - `main.cpp` - build fails with `DO_BA_BLOCK` and `DO_EIGEN`
- Ceres
    - Memory issue when building GMM at instance sizes above about d=20, K=50
- MuPad
    - Missing mex files for MuPad_Hand
- Theano
    - `run.bat` - remove hard path to Miniconda
