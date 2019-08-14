# C++ Runner

## Overview
C++ Runner is one of _benchmark runners_ described in Architecture.md. C++ runner loads and runs _testing modules_, which in this case are dynamic shared libraries with ".dll" extension on all platforms. 

Each _testing module_ contains implementation of some alghorithm computing objective functions and their derivatives. Each objective should be supported by both runner and module to be benchmarked.

The runner has no information about objective types supported by module. Howerever, a module may support only some of the objective types. That's why if a user asks the runner to benchmark any of unsupported objectives, the runner throws an exception.

Each module provides classes to load data in the module, calculate objective, its derivative and output results. Such classes always inherit templated _ITest_ interface.

There is also a one exported constructing function for each such class in each module.

## Supported Objective Types
Currently supported objective types:
	 
| Full Name | Short Name |
|--|--|
| Gaussian Mixture Model Fitting | GMM |
| Bundle Adjustment| BA |
| Hand Tracking | Hand |
| Long short-term memory | LSTM |

Conformity table of objective types and constructing functions:

| Short Type Name | Function Name |
|--|--|
| GMM | get_gmm_test |
| BA| get_ba_test |
| Hand | get_hand_test |
| LSTM | get_lstm_test|


## Command Line

CPPRunner test_type module_path input_filepath output_dir minimum_measurable_time nruns_F nruns_J time_limit [-rep]

## Adding new modules

## Adding new objective type