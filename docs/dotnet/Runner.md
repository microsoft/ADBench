# .NET Core Runner

## Overview
.NET Core Runner is one of the _benchmark runners_ described in [Architecture.md](../Architecture.md). .NET Core runner loads and runs _testing modules_, which in this case are .NET Core assemblies with `.dll` extension on all platforms. 

Every _testing module_ contains an implementation of some algorithm computing objective functions and their derivatives. Every objective should be supported by both the runner and the module to be benchmarked.

A module doesn't have to support all of the objective types. If a user asks the runner to benchmark an unsupported objective, the runner prints an error and stops.

Every module, for every objective it supports, defines a class that implements the corresponding instantiation of the generic [`ITest<TInput, TOutput>`](./Modules.md#itest-implementation) interface. That class is exported via MEF.

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
dotnet DotnetRunner.dll test_type module_path input_filepath output_dir minimum_measurable_time nruns_F nruns_J time_limit [-rep]
```

 - `test_type` - The short type name of the objective function. It may also be equal to "Hand-Complicated" that designates the complicated case of the "Hand" objective, where the variable U is considered (see [srajer-autodiff-screen.pdf](../../Documents/srajer-autodiff-screen.pdf), page 5).
 - `module_path` - an absolute or relative path to an assembly containing the `ITest<>` implementation to be benchmarked.
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

 1. Define `TInput`, `TOutput`, and, if necessary, `TParameters` types in the `/src/dotnet/runner/Data/TData.cs` file where `T` is the name of the new objective. Keep them in the `DotnetRunner.Data` namespace.

    `TInput` is the data type for the new objective's inputs, `TOutput` is a structure that contains outputs of both new objective function and its target Jacobian.
    `TParameters` is a data type containing all configurable parameters of the benchmark. If there are no such parameters then it can be omitted.

 2. In the `ModuleLoader` class (`/src/dotnet/runner/ModuleLoader.cs`) add the following function:
    ```csharp
    public ITest<GMMInput, GMMOutput> GetTTest()
    {
        if (container.TryGetExport(out ITest<TInput, TOutput> tTest))
            return tTest;
        else
            throw new InvalidOperationException("The specified module doesn't support the T objective.");
    }
    ```
    Where `T` still is the name of the new objective.

 3. Create `/src/dotnet/runner/Benchmarks/TBenchmark.cs` with the following content:
    ```csharp
    using DotnetRunner.Data;
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;

    namespace DotnetRunner.Benchmarks
    {
        public class TBenchmark : Benchmark<TInput, TOutput, TParameters>
        {
            protected override TInput ReadInputData(string inputFilePath, TParameters parameters)
            {
                // implementation
            }

            protected override ITest<TInput, TOutput> GetTest(ModuleLoader moduleLoader)
            {
                return moduleLoader.GetBATest();
            }

            protected override void SaveOutputToFile(TOutput output, string outputPrefix, string input_basename, string module_basename)
            {
                // implementation
            }
        }
    }
    ```

    If you opted to omit defining `TParameters` type on step one, then inherit from `Benchmark<TInput, TOutput>` instead. `ReadInputData` in that case would have the following signature:
    ```csharp
    protected override TInput ReadInputData(string inputFilePath, DefaultParameters parameters)
    ```

    Implement the methods so that they would:

    - 
      ```csharp
      protected override TInput ReadInputData(string inputFilePath, TParameters parameters)
      ```
          
      Open input_file and loads data to the structure of the TInput type. 
      
      The format of the input file is specific for the objective type.
    - 
      ```csharp
      protected override void SaveOutputToFile(TOutput output, string outputPrefix, string input_basename, string module_basename)
      ```
          
      Save the results of computations stored in an object of the `TOutput` type to the output files:
      
        - `output_prefix + input_basename + "_F_" + module_basename + ".txt"` - stores the value of the objective function
        - `output_prefix + input_basename + "_J_" + module_basename + ".txt"` - stores the value of the objective function derivative

      The format of the output files is specific for the objective type.
4.  Add a new else-if branch to the `main` function in `Program.cs` as follows:
    ```csharp
    if (testType == "GMM")
    {
        var benchmark = new GMMBenchmark();
        benchmark.Run(modulePath, inputFilePath, outputPrefix, minimumMeasurableTime, nrunsF, nrunsJ, timeLimit, new GMMParameters() { ReplicatePoint = replicate_point });
    }
        ...
    else if (testType == "T")
    {
        var benchmark = new TBenchmark();
        benchmark.Run(modulePath, inputFilePath, outputPrefix, minimumMeasurableTime, nrunsF, nrunsJ, timeLimit, new TParameters() { ... });
    }  
        ...
    ```
    If you don't use `TParameters` just skip it here.

## Input/Output files format

See [FileFormat.md](../FileFormat.md#input/output-files-format).