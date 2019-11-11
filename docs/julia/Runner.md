# Julia Runner

## Overview
Julia Runner is one of the _benchmark runners_ described in [Architecture.md](../Architecture.md). Julia runner loads and runs _testing modules_, which in this case are modules in the sense of Julia language. 

Every _testing module_ contains an implementation of some algorithm computing objective functions and their derivatives. Every objective should be supported by both the runner and the module to be benchmarked.

A module doesn't have to support all of the objective types. If a user asks the runner to benchmark an unsupported objective, the runner prints an error and stops.

Every module, for every objective it supports, exports a parameterless factory function that returns an object of the corresponding instantiation of generic [`Test{Input, Output}`](./Modules.md#itest-implementation) type.

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
julia --project=/path/to/repo/JuliaProject.toml --optimize=3 Runner.jl test_type module_path input_filepath output_dir minimum_measurable_time nruns_F nruns_J time_limit [-rep]
```

 - `test_type` - the short type name of the objective function. It may also be equal to "Hand-Complicated" that designates the complicated case of the "Hand" objective, where the variable U is considered (see [srajer-autodiff-screen.pdf](../../Documents/srajer-autodiff-screen.pdf), page 5).
 - `module_path` - an absolute or relative path to a `.jl` file containing the module to be benchmarked.
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

1. Define a module `TData` in the `/src/julia/shared/TData.jl` file where `T` is the name of the new objective. In that module define and export the following

    ```julia
    struct TInput
    ```
    The data type for the new objective's inputs.
    ```julia
    mutable struct TOutput
    ```
    A mutable structure that can hold outputs of both new objective function and its target Jacobian.
    ```julia
    function empty_t_output()::TOutput
    ```
    A function that returns an empty object of the `TOutput` type, that later will be populated by the benchmarked module.
    ```julia
    function load_t_input(fn::AbstractString)::TInput
    ```
    Open input file `fn` and loads data to the structure of the `TInput` type.

1. Add 
    ```julia
    using TData
    ```
    To all modules (Benchmark, DataUtils, Runner, and TestLoader) defined in the `src/julia/runner` folder.

1. In the `TestLoader` module (`/src/julia/runner/TestLoader.jl`) add the following function:
    ```julia
    get_t_test(module_name::AbstractString)::Test{TInput, TOutput} = get_test("t", module_name)
    ```
    Where `T` still is the name of the new objective.

    Then, add a new method to `get_test_for` function:
    ```julia
    get_test_for(input::TInput, output::TOutput, module_name::AbstractString)::Test{TInput, TOutput} = get_t_test(module_name)
    ```

1. In the `DataUtils` module (`/src/julia/runner/DataUtils.jl`) add, export, and implement the following function:
    ```julia
    function save_t_output_to_file(output::TOutput, output_prefix::AbstractString, input_name::AbstractString, module_name::AbstractString)
        # implementation
    end
    ```
    This function should save the results of computations stored in an object of the `TOutput` type to the output files:
      
    - `output_prefix + input_basename + "_F_" + module_basename + ".txt"` - stores the value of the objective function
    - `output_prefix + input_basename + "_J_" + module_basename + ".txt"` - stores the value of the objective function derivative

    The format of the output files is specific for the objective type. Please, use the utility functions already defined in the module.

    Then, add a method to the `create_empty_output_for` function:
    ```julia
    create_empty_output_for(::TInput) = empty_t_output()
    ```
    and a method for the `save_output_to_file` function:
    ```julia
    save_output_to_file(output::TOutput, output_prefix::AbstractString, input_name::AbstractString, module_name::AbstractString) = save_t_output_to_file(output, output_prefix, input_name, module_name)
    ```

1.  Add a new else-if branch to the `Runner` module (`/src/julia/runner/Runner.jl`) as follows:
    ```julia
    if test_type == "gmm"
        input = load_gmm_input(input_filepath, replicate_point)
        module_display_name = module_name[1:end - 3]
    elseif 
        ...
    elseif test_type == "t"
        input = load_t_input(input_filepath)
        module_display_name = module_name[1:end - <length of "t">]
    else
        throw(ArgumentError("Julia runner doesn't support tests of $test_type type."))
    end
    ```

## Input/Output files format

See [FileFormat.md](../FileFormat.md#input/output-files-format).