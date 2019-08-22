# C++ Runner

## Overview
C++ Runner is one of the _benchmark runners_ described in [Architecture.md](../Architecture.md#benchmark-runners). C++ runner loads and runs _testing modules_, which in this case are dynamic shared libraries with ".dll" extension on all platforms. 

Each _testing module_ contains implementation of some alghorithm computing objective functions and their derivatives. Each objective should be supported by both runner and module to be benchmarked.

The runner has no information about objective types supported by module. Howerever, a module may support only some of the objective types. That's why if a user asks the runner to benchmark any of unsupported objectives, the runner throws an exception.

Each module provides classes to load data in the module, calculate objective, its derivative and output results. Such classes always inherit templated _ITest_ interface.

There is also a one exported constructing function for each such class in each module.

## Supported Objective Types
Currently supported objective types and their constructing functions:
	 
| Full Name | Short Name | Function Name |
| -- | -- | -- |
| Gaussian Mixture Model Fitting | GMM | get_gmm_test |
| Bundle Adjustment| BA | get_ba_test |
| Hand Tracking | Hand | get_hand_test |
| Long short-term memory | LSTM | get_lstm_test |


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
  - time_limit - soft (see [Architecture.md](../Architecture.md)) time limit for benchmarking the computation of either the objective function or its gradient/Jacobian.
  - \-rep *(applycable only for GMM)* - if enabled all input data points take one common value.

## Adding new modules
(see [Modules.md](./Modules.md))
## Adding new objective types

 1. Define *TInput*, *TOutput* and (if necessary) *TParameters* structs in the "/src/cpp/shared/TData.h" file where T is a name of a new objective. 

	*TInput* and *TOutput* should contain fields for all possible input/output data. 
	*TParameters* should contain fields for all configurable parameters of benchmark. If no such parameters in the benchmark then use *DefaultParameters* struct further.

 2. In the *ModuleLoader* class (/src/cpp/runner/ModuleLoader.h) implement the following function:
	```
	std::unique_ptr<ITest<TInput, TOutput>> get_T_test() const;
	```
 3. Create "/src/cpp/modules/TBenchmark.h" to read as follows and implement defined functions in the "TBenchmark.cpp":
	 ```
	#pragma once

	#include "Benchmark.h"

	template<>
	TInput read_input_data<TInput, TParameters>(const std::string& input_file, const TParameters& params);

	template<>
	unique_ptr<ITest<TInput, TOutput>> get_test<TInput, TOutput>(const ModuleLoader& module_loader);

	template<>
	void save_output_to_file<TOutput>(const TOutput& output, const string& output_prefix, const string& input_basename,
	                                    const string& module_basename);

	 ```
4.  Include "TBenchmark.h" in "main.cpp" and add a new else-if branch to the "main" function as follows:
	```
	if (test_type == "GMM") {
        run_benchmark<GMMInput, GMMOutput, GMMParameters>(module_path, input_filepath, output_prefix, minimum_measurable_time, nruns_F, nruns_J, time_limit, { replicate_point });
    }
	    ...
	else if (test_type == "T") {
            run_benchmark<TInput, TOutput, TParameters>(module_path, input_filepath, output_prefix, minimum_measurable_time, nruns_F, nruns_J, time_limit, parameters);
    }  
	    ...
	```
5. Add *TBenchmark.cpp* to *TestExtenders* environment variable inside "/src/cpp/runner/CMakeLists.txt". 
