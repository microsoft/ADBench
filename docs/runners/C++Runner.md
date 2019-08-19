# C++ Runner

## Overview
C++ Runner is one of _benchmark runners_ described in [Architecture.md](./Architecture.md). C++ runner loads and runs _testing modules_, which in this case are dynamic shared libraries with ".dll" extension on all platforms. 

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

```
CPPRunner test_type module_path input_filepath output_dir minimum_measurable_time nruns_F nruns_J time_limit [-rep]
```

 - test_type - a type of a benchmarking objective function. It should accept short type name of an objective as a value. In the case of "Hand" it also may be equal to "Hand-Complicated" that allows to enable/disable calculation of the exact correspondence spots inside the triangles.
 - module_path - an absolute or relative path to a .dll module.
 - input_filepath - an absolute or relative path to an input file.
  - output_dir - a directory where output files will be stored.
  -  minimum_measurable_time - minimum time that computation needs to run to produce a reliable measurement.
  - nruns_F - maximum number of times to run the computation the objective function for timing.
  - nruns_J  - maximum number of times to run the computation of the considered derivative (gradient or Jacobian) for timing.
  - time_limit - soft (see [Architecture.md](./Architecture.md)) time limit for benchmarking the computation of either the objective function or its gradient/Jacobian.
  - \-rep *(applycable only for GMM)* - if enabled all input data points take one common value.
## Adding new modules

## Adding new objective types