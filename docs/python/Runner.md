# Python Runner

## Overview
Python Runner is one of the _benchmark runners_ described in [Architecture.md](../Architecture.md). Python runner loads and runs _testing modules_, which in this case are modules in the sense of Python language. 

Every _testing module_ contains an implementation of some algorithm computing objective functions and their derivatives. Every objective should be supported by both the runner and the module to be benchmarked.

A module doesn't have to support all of the objective types. If a user asks the runner to benchmark an unsupported objective, the runner prints an error and stops.

<!-- Every module, for every objective it supports, exports a parameterless factory function that returns an object of the corresponding instantiation of generic [`Test{Input, Output}`](./Modules.md#itest-implementation) type. -->

## Supported Objective Types
Currently supported objective types:

| Full Name | Short Name |
| -- | -- |
| Gaussian Mixture Model Fitting | GMM |
| Bundle Adjustment| BA |
| Hand Tracking | Hand |
| Long short-term memory | LSTM |


## Command Line

```powershell
python3 /path/to/repo/src/python/runner/main.py test_type module_path input_filepath output_dir minimum_measurable_time nruns_F nruns_J time_limit [-rep]
```

 - `test_type` - The short type name of the objective function. It may also be equal to "Hand-Complicated" that designates the complicated case of the "Hand" objective, where the variable U is considered (see [srajer-autodiff-screen.pdf](../../Documents/srajer-autodiff-screen.pdf), page 5).
 - `module_path` - an absolute or relative path to a `.py` file containing the module to be benchmarked.
 - `input_filepath` - an absolute or relative path to the input file.
 - `output_dir` - a directory where the output files should be stored.
 - `minimum_measurable_time` - minimum time that the computation needs to run to produce a reliable measurement.
 - `nruns_F` - maximum number of times to run the computation of the objective function for timing.
 - `nruns_J` - maximum number of times to run the computation of the considered derivative (gradient or Jacobian) for timing.
 - `time_limit` - soft (see [Methodology.md](../Methodology.md)) time limit for benchmarking the computation of either the objective function or its gradient/Jacobian.
 - `-rep` *(applicable only for GMM)* - if enabled, all input data points are expected to have one shared value.

## Adding new modules
(see [Modules.md](./Modules.md))

## Adding new objective types

1. Define `TInput` and `TOutput` classes in the `/src/python/shared/TData.py` file where `T` is the name of a new objective. 

    `TInput` is the data type for the new objective's inputs, `TOutput` is a structure that contains outputs of both new objective function and its target jacobian. Also `TOutput` contains `save_output_to_file` function

    ```python
    def save_output_to_file(
        self,
        output_prefix,
        input_basename,
        module_basename
    )
    ```

    Which saves results of computations stored in a structure of the TOutput type to the output files:

    - `output_prefix + input_basename + "_F_" + module_basename + ".txt"` - stores the value of the objective function
    - `output_prefix + input_basename + "_J_" + module_basename + ".txt"` - stores the value of the objective function derivative

      The format of the output files is specific for each objective type.

1. In the `input_utils` (`/src/python/shared/input_utils.py`) add the following function:
    ```python
    def read_T_instance(fn):
    ```
    It open input file `fn` and loads data to the structure of the `TInput` type.

1.  Add a new else-if branch to the `Runner` (`/src/python/runner/main.py`) as follows:
    ```python
    if test_type == "GMM":
        # read gmm input
        _input = input_utils.read_gmm_instance(input_filepath, replicate_point)
    elif
        ...
    elif test_type == "T"
        _input = input_utils.read_T_instance(input_filepath)
    else:
        raise RuntimeError("Python runner doesn't support tests of " + test_type + " type")
    ```

## Input/Output files format

See [FileFormat.md](../FileFormat.md#input/output-files-format).