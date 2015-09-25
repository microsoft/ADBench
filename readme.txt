Matlab directory contains the following scripts:
control_script_gmm.m
control_script_ba.m
control_script_hand.m

Those are used to generate problem instances, generate makefiles which run all the experiments and then read results and plot them. Only exception are ADiMat and MuPAD, which are ran from MATLAB.

All the clients for non-MATLAB tools are contained in VS project AutodiffTools.sln.