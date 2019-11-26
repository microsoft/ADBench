# Global Runner

The _global runner_ described in [Architecture.md](./Architecture.md#global-runner) is implemented as a PowerShell script `ADBench/run-all.ps1`. This document describes its exact functionality, interfaces with other components of ADBench, and provides a user guide.

## Functionality

When invoked, the script will run a set of benchmarks on a set of [_testing modules_](./Architecture.md#testing-modules). Both sets have default values, that can be overridden by passing specific arguments to the script.

The default set of benchmarks includes:
- All GMM problems with 1k and 10k points defined in `/data/gmm` folder
- 5 (out of 20 present in `/data/ba`) smallest BA problems
- 5 (out of 12 present in `/data/hand`) Hand Tracking problems of every kind (simple-small, simple-big, complicated-small, complicated-big)
- All LSTM problems defined in `/data/lstm` folder

The default set of _testing modules_ includes all testing modules [registered](#interfacing-with-testing-modules) with the script.

Unless excluded, `run-all.ps1` will run benchmarks on the `Manual` module first in order to produce the _golden Jacobians_, which will be used to check the correctness of the Jacobians produced by all other modules. See [Jacobian Correctness Verification](./JacobianCheck.md) for the details and the justification.

For every specified _testing module_ `run-all.ps1` will run every specified benchmark that this module supports. So, e.g. if BA benchmarks were requested, but some of the requested modules don't support BA, then BA benchmarks won't be run on these modules and such behavior won't be considered an error.

The script will run benchmarks on _testing modules_ using the corresponding [_benchmark runners_](./Architecture.md#benchmark-runners). It will enforce the hard timeout (default - 5 minutes, overridable in the corresponding argument) by terminating the runner processes as necessary. It will check that the runner produces a file with timings and a file with the result Jacobian. Then it will compare the result Jacobian to the golden one and output the result of the comparison in JSON format. Unless overridden in the corresponding argument, `run-all.ps1` will delete files with Jacobians it considered correct during comparison.

The script checks guaranteed timeouts. This means that the benchmark for the bigger test will not be run if the run test for the smaller size finishes with timeout. Thus, a GMM objective test will not be run in any case where the `d` and `K` values are both greater than or equal to the `d` and `K` values of a previously timed-out test (of the same count of points). For LSTM such a timeout checking is the same (but for `l` and `c` instead of `d` and `K` respectively). BA and Hand tests with the bigger order number will not be run if any test with the less number is terminated due to timeout. So, for them tests are expected to be sorted respective their sizes.

Timeouts, missing output files, and failed comparisons to the golden Jacobians are all considered to be _non-fatal errors_. They cause a warning to be printed when the script finishes and make script's exit code to become non-zero, but don't prevent the execution of other benchmarks.

## Usage

Run from PowerShell command prompt. Syntax:

```powershell
    ./run-all.ps1 [[-buildtype] <String>] [[-minimum_measurable_time] <Double>] [[-nruns_f] <Int32>] [[-nruns_J] <Int32>] [[-time_limit] <Double>] [[-timeout] <Double>] [[-tmpdir] <String>] [-repeat] [-repeat_failures] [[-tools] <String[]>] [-keep_correct_jacobians] [[-gmm_d_vals_param] <Int32[]>] [[-gmm_k_vals_param] <Int32[]>] [[-gmm_sizes] <String[]>] [[-hand_sizes] <String[]>] [[-ba_min_n] <Int32>] [[-ba_max_n] <Int32>] [[-hand_min_n] <Int32>] [[-hand_max_n] <Int32>] [[-lstm_l_vals] <Int32[]>] [[-lstm_c_vals] <Int32[]>]
```    

Parameters:

- `-buildtype <String>`

    Which build to test. Builds should leave a script file `cmake-vars-$buildtype.ps1` in the ADBench directory, which sets `$bindir` to the build directory. And if only some D,K are valid for GMM, sets `$gmm_d_vals`, and `$gmm_k_vals`.
    
- `-minimum_measurable_time <Double>`

    Estimated time of accurate result achievement. A runner cyclically reruns measured function until total time becomes more than that value. Supported only by benchmark the runner-based tools (those with ToolType `cpp`, `dotnet`, `julia`, or `python`).
    
- `-nruns_f <Int32>`

    Maximum number of times to run the function for timing.
    
- `-nruns_J <Int32>`

    Maximum number of times to run the Jacobian for timing.
    
- `-time_limit <Double>`

    How many seconds to wait before we believe we have accurate timings.
    
- `-timeout <Double>`

    Kill the test after this many seconds.
    
- `-tmpdir <String>`

    Where to store the ouput, defaults to `tmp/` in the project root.
    
- `-repeat [<SwitchParameter>]`

    Repeat tests, even if output file exists.
    
- `-repeat_failures [<SwitchParameter>]`

    Repeat only failed tests.
    
- `-tools <String[]>`

    List of tools to run.
    
- `-keep_correct_jacobians [<SwitchParameter>]`

    Don't delete produced jacobians even if they're accurate.
    
- `-gmm_d_vals_param <Int32[]>`

    GMM D values to try. Must be a subset of the list of compiled values in `ADBench/cmake-vars-$buildtype.ps1`.
    
- `-gmm_k_vals_param <Int32[]>`

    GMM K values to run. As above.
    
- `-gmm_sizes <String[]>`

    GMM sizes to try. Must be a subset of `@("1k", "10k", "2.5M")`. 2.5M currently is not supported.
    
- `-hand_sizes <String[]>`

    Hand problem sizes to try. Must be a subset of `@("small", "big")`.
    
- `-ba_min_n <Int32>`

    Number of the first BA problem to try. Must be between `1` and `ba_max_n`.
    
- `-ba_max_n <Int32>`

    Number of the last BA problem to try. Must be between `ba_min_n` and `20`.
    
- `-hand_min_n <Int32>`

    Number of the first Hand problem to try. Must be between `1` and `hand_max_n`.
    
- `-hand_max_n <Int32>`

    Number of the last Hand problem to try. Must be between `hand_min_n` and `12`.
    
- `-lstm_l_vals <Int32[]>`

    Numbers of layers in LSTM to try. Must be a subset of `@(2, 4)`.
    
- `-lstm_c_vals <Int32[]>`

    Sequence lengths in LSTM to try. Must be a subset of `@(1024, 4096)`.

Example:
```powershell
./run-all.ps1 -buildtype "Release" -minimum_measurable_time 0.5 -nruns_f 10 -nruns_J 10 -time_limit 180 -timeout 600 -tmpdir "C:/path/to/tmp/" -tools @("Finite", "Manual", "PyTorch") -gmm_d_vals_param @(2,5,10,64)
```

This will:
- Run only release builds.
- Loop measured function while total calculation time is less than 0.5 seconds.
- Aim to run 10 tests of each function, and 10 tests of the derivative of each function.
- Stop (having completed a whole number of tests) at any point after 180 seconds.
- Allow each program a maximum of 600 seconds to run all tests.
- Output results to `C:/path/to/tmp/`.
- Not repeat any tests for which there already exist a results file.
- Run only Finite, Manual, and PyTorch.
- Try GMM d values of 2, 5, 10, 64.

## Interfaces

This section describes, how `run-all.ps1` interfaces with other components of ADBench.

### Interfacing with Benchmark Runners

`run-all.ps1` is aware of and knows how to invoke all benchmark runners.

First, there's an enumeration `ToolType` that lists names of runners. These names are local to the script. Then, the method `[Tool]::run(...)` contains an `if...elseif...` block, that has a clause for every runner, in which that runner is invoked to perform a specific benchmark. These are the two places, one would need to modify to make `run-all.ps1` support a new runner.

When the benchmark runner finishes, `run-all.ps1` checks that it produced a file with timings (`<name of the input>_times_<name of the testing module>.txt`) and a file with the result Jacobian (`<name of the input>_J_<name of the testing module>.txt`) in the specified folder. Any of these files missing is a non-fatal error. Then it checks the correctness of the Jacobian. For that to be possible, the file with the Jacobian must have a format described in [FileFormat.md](./FileFormat.md).

### Interfacing with Testing Modules

While `run-all.ps1` does not interface with the testing modules directly - we have benchmark runners for that, all testing modules still must be listed in this script for it to be aware of their existence, supported objectives, and required benchmark runner.

To add a new testing module to `run-all.ps1`, find an array `$tool_descriptors` near the end of the script and add a new `[Tool]` object to it. The syntax of the `Tool`'s constructor is
```powershell
[Tool]::new("<Testing module name>", "<Benchmark runner name>", [ObjectiveType] "<Supported objectives>", $true, <tolerance>)
```
Here
- `<Testing module name>` is the name of your module,
- `<Benchmark runner name>` is the name of the benchmark runner that can invoke your module as listed in the [`ToolType` enumeration](#interfacing-with-benchmark-runners),
- `<Supported objectives>` is a comma-separated list of objective function names supported by your module. Possible names are GMM, BA, Hand, and LSTM,
- `<tolerance>` is the maximum error, values of the Jacobians produced by your module are allowed to have. Use `$default_tolerance` unless there's some specific reason for your module to produce results of non-standard accuracy.
See [JacobianCheck.md](./JacobianCheck.md#comparing-jacobians) for the definition of error.


### Output

`run-all.ps1` outputs its logs into standard output.

For every benchmark `run-all.ps1` performs, it produces a number of file outputs. These files are placed in the following folder
```
/<path to tmp>/<build config>/<objective>/<objective subtype>/<testing module>/
```
Here
- `<path to tmp>` is the path passed to the script in the `tmpdir` parameter, which defaults to `tmp` folder in the root of the repository.
- `<build config>` is the configuration of the build passed to the script in the `buildtype` parameter, which defaults to `Release`.
- `<objective>` is the short name of the objective function in lowercase (so it's one of "gmm", "ba", "hand", and "lstm").
- `<objective subtype>` is an optional subtype specific to the objective. For the GMM objective it's the number of points ("1k", "10k", or "2.5M"), for the Hand objective it's `<complexity>_<size>`, where `<complexity>` is either "simple" or "complicated", and `<size>` is either "big" or "small". BA and LSTM have no subtypes.
- `<testing module>` is the name of the testing module.

The outputs themselves are:
- `<name of the input>_times_<name of the testing module>.txt` - new line-separated timings for the computation of the objective function and the derivative. Produced by the benchmark runner, unless it timed out, in which case `run-all.ps1` produces this file by itself (with `inf` values for both times).
- `<name of the input>_F_<name of the testing module>.txt` - new line-separated values of the objective function computed by the module. Produced by the benchmark runner.
- `<name of the input>_J_<name of the testing module>.txt` - values of the derivative computed by the module. Exact format is specific to the objective function. See [FileFormat](./FileFormat.md) for details. Produced by the benchmark runner. Unless explicitly instructed otherwise, `run-all.ps1` deletes these files if they pass the correctness test.
- `<name of the input>_correctness_<name of the testing module>.txt` - JSON files with the results of correctness checking. Produced by `run-all.ps1`. These files have the following format:
```json
{
    "Tolerance": <double>,
    "File1": "/path/to/Jacobian/being/checked.txt",
    "File2": "/path/to/golden/Jacobian.txt",
    "DimensionMismatch": <bool>,
    "ParseError": <bool>,
    "MaxDifference": <double>,
    "AvgDifference": <double>,
    "DifferenceViolationCount": <int>,
    "NumberComparisonCount": <int>,
    "Error": "Text of the error, that caused the termination of the comparison, if any",
    "ViolationsHappened": <bool>
}
```
Here
- `Tolerance` is the maximum [difference](./JacobianCheck.md#comparing-jacobians) between the values of compared Jacobians that was not considered an error.
- `DimensionMismatch` is true, when the compared Jacobians have different sizes, false otherwise.
- `ParseError` is true, when the parsing of at least one of the compared files ended in an error, false otherwise.
- `MaxDifference` is the maximum [difference](./JacobianCheck.md#comparing-jacobians) encountered while comparing the corresponding values of the two Jacobians.
- `AvgDifference`is the average [difference](./JacobianCheck.md#comparing-jacobians) encountered while comparing the corresponding values of the two Jacobians.
- `DifferenceViolationCount` is the number of times the [difference](./JacobianCheck.md#comparing-jacobians) encountered while comparing the corresponding values of the two Jacobians exceeded the `Tolerance`.
- `NumberComparisonCount` is the number of times the corresponding values of the two Jacobians were compared before the comparison ended (possibly, due to an error).
- `ViolationsHappened` is true if `DifferenceViolationCount` is non-zero or if an error happened during the comparison.