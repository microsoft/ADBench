



# C++ Runner

## Overview
C++ Runner is one of the _benchmark runners_ described in [Architecture.md](../Architecture.md). C++ runner loads and runs _testing modules_, which in this case are dynamic shared libraries with ".dll" extension on all platforms. 

Each _testing module_ contains an implementation of some alghorithm computing objective functions and their derivatives. Each objective should be supported by both the runner and the module to be benchmarked.

The runner has no information about the objective types supported by module. Howerever, a module may support only some of the objective types. That's why if a user asks the runner to benchmark any of unsupported objectives, the runner prints an error to `stderr` and stops.

Every module, for every objective it supports, defines a class that implements the corresponding templated [_ITest_](./Modules.md#itest-implementation) interface.

There is also a one exported factory function for each such class in each module.

## Supported Objective Types
Currently supported objective types and their factory functions:
     
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

 - test_type - A short type name of a benchmarking objective function. It may also be equal to "Hand-Complicated" that designates the complicated case of the "Hand" objective, where the variable U is considered (see [srajer-autodiff-screen.pdf](../../Documents/srajer-autodiff-screen.pdf), page 5).
 - module_path - an absolute or relative path to a .dll module responsible for testing algorithm of calculation.
 - input_filepath - an absolute or relative path to an input file.
 - output_dir - a directory where output files will be stored.
 - minimum_measurable_time - minimum time that computation needs to run to produce a reliable measurement.
 - nruns_F - maximum number of times to run the computation of the objective function for timing.
 - nruns_J - maximum number of times to run the computation of the considered derivative (gradient or Jacobian) for timing.
 - time_limit - soft (see [Methodology.md](../Methodology.md)) time limit for benchmarking the computation of either the objective function or its gradient/Jacobian.
 - \-rep *(applycable only for GMM)* - if enabled all input data points have one shared value.

## Adding new modules
(see [Modules.md](./Modules.md))
## Adding new objective types

 1. Define *TInput*, *TOutput* and (if necessary) *TParameters* structs in the "/src/cpp/shared/TData.h" file where T is the name of a new objective. 

    *TInput* is the data type for the new objective's inputs, *TOutput* is a structure that contains outputs of both new objective function and its target jacobian.
    *TParameters* is a data type containing all configurable parameters of the benchmark. If there're no such parameters in the benchmark then just use the *DefaultParameters* struct.

 2. In the *ModuleLoader* class (/src/cpp/runner/ModuleLoader.h) implement the following function:
    ```
    std::unique_ptr<ITest<TInput, TOutput>> get_T_test() const;
    ```
    It should find a function with the same name in the future shared library, execute it and return its result. In the case of the error it should throw a runtime_error. 
    
    Note that this function should be really similar to those already existing, for example "get_gmm_test".
 3. Create "/src/cpp/runner/TBenchmark.h" with the following content:
    ```
    #pragma once

    #include "Benchmark.h"
    ```

    Define the following functions in the "TBenchmark.h" and implement them in the "TBenchmark.cpp":

    - ```
      template<>
      TInput read_input_data<TInput,TParameters>(const std::string& input_file, const TParameters& params);
      ```
          
      Opens input_file and loads data to the structure of the TInput type. 
      
      The format of the input file is specific for each objective type.
    - ```
      template<>
      unique_ptr<ITest<TInput, TOutput>> get_test<TInput, TOutput>(const ModuleLoader& module_loader);
      ```
          
      Chooses and calls the right method of the ModuleLoader corresponding to the TInput and TOutput types.
    - ```
      template<>
      void save_output_to_file<TOutput>(const TOutput& output, const string& output_prefix, const string& input_basename,
                                        const string& module_basename);
      ```
          
      Saves results of computations stored in a structure of the TOutput type to the output files:
      
        - output_prefix + input_basename + "\_F\_" + module_basename + ".txt" - stores the value of the objective function
        - output_prefix + input_basename + "\_J\_" + module_basename + ".txt" - stores the value of the objective function derivative
          
      The format of the output files is specific for each objective type.
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

## Input/Output files format

### GMM
#### Input
  D k n</br>
  α<sub>1</sub></br>
    ...</br>
  α<sub>k</sub></br>
  μ<sub>1,1</sub> ... μ<sub>D,1</sub></br>
    ...</br>
  μ<sub>1,k</sub> ... μ<sub>D,k</sub></br>
  q<sub>1,1</sub> ... q<sub>D,1</sub> l<sub>1,1</sub> ... l<sub>$\frac{D(D-1)}{2}$,1</sub></br>
    ...</br>
  q<sub>1,k</sub> ... q<sub>D,k</sub> l<sub>1,k</sub> ... l<sub>$\frac{D(D-1)}{2}$,k</sub></br> 
  x<sub>1,1</sub> ... x<sub>D,1</sub></br>
    ...</br>
  x<sub>1,n</sub> ... x<sub>D,n</sub></br>
  γ m</br>
  
Definitions of all variables are given in the  [srajer-autodiff-screen.pdf](../../Documents/srajer-autodiff-screen.pdf), page 3.
Note that if replicate point mode is enabled the benchmark expects only x<sub>1,1</sub> ... x<sub>D,1</sub> string and duplicates it n-1 times.

#### Output

1. \_F\_ file  
    Contains only the value of the function in the specified point. 
2. \_J\_ file  
     v<sub>1</sub> ... v<sub>n</sub>      where v<sub>i</sub> are components of the objective gradient.
     
### BA
#### Input
  n m p</br>
  p<sub>1</sub> ... p<sub>11</sub></br>
  x<sub>1</sub> x<sub>2</sub> x<sub>3</sub></br>
  w<sub>1</sub></br>
  feat<sub>1</sub> feat<sub>2</sub></br>

n,m,p are number of cams, points and observations.
Definitions of all other variables are given in the  [srajer-autodiff-screen.pdf](../../Documents/srajer-autodiff-screen.pdf), page 5.

#### Output

1. \_F\_ file  
    Reprojection error
    Zach weight error
2. \_J\_ file  
     j<sub>1,1</sub> ... j<sub>1,ncols</sub> 
     ...
      j<sub>nrows,1</sub> ... j<sub>nrows,ncols</sub> 
    
    where ncols=2*p+p, nrows=11*n+3*m+p

### Hand
#### Input
1. model/bones.txt
	Contains a list of lines whereas each line containts such parameters separated by ":" delimeter:
	- bone_name
	- bone_parent
	- base_relative<sub>1</sub> ... base_relative<sub>16</sub>
	- base_absolute<sub>1</sub> ... base_absolute<sub>16</sub>
2. model/vertices.txt
    Contains a list of lines whereas each line containts such parameters separated by ":" delimeter:
	- v<sub>1</sub> ... v<sub>3</sub>
	- dummy<sub>1</sub> ... dummy<sub>5</sub>
	- n
	- bone<sub>1</sub>:weight<sub>bone<sub>1</sub>,vert<sub>1</sub></sub>: ... :bone<sub>n</sub>:weight<sub>bone<sub>n</sub>,vert<sub>n</sub></sub>

3. model/triangles.txt
    Contains a list of lines:  
      - v<sub>1</sub>:v<sub>2</sub>:v<sub>3</sub>
 
 4. input.txt
    
      n_pts  n_theta</br>
      correspondance<sub>1</sub> point<sub>1,1</sub> point<sub>1,2</sub> point<sub>1,3</sub></br>
        ...</br>
      correspondance<sub>n_pts</sub> point<sub>n_pts,1</sub> point<sub>n_pts,2</sub> point<sub>n_pts,3</sub></br>
      us<sub>1,1</sub> us<sub>1,2</sub></br>
        ...</br>
      us<sub>n_pts,1</sub> us<sub>n_pts,2</sub></br>
      θ<sub>1</sub></br>
        ...</br>
      θ<sub>n_theta</sub></br>
   
Note that the benchmark expects "us" block only if complicated mode is enabled.

#### Output
1. \_F\_ file  
     v<sub>1</sub> ... v<sub>n</sub>      where v<sub>i</sub> are components of the objective vector.
2. \_J\_ file  
     j<sub>1,1</sub> ... j<sub>1,ncols</sub> 
     ...
      j<sub>nrows,1</sub> ... j<sub>nrows,ncols</sub> 
    
    where ncols=(complicated ? 2 : 0) + n_theta, nrows=3*n_pts

### LSTM
#### Input
  l c b</br>
  main_param<sub>1</sub> ... main_param<sub>2*l*4*b</sub></br>
  extra_param<sub>1</sub> ... extra_param<sub>3*b</sub></br>
  state<sub>1</sub> ... state<sub>2*l*b</sub></br>
  seq<sub>1</sub> ... seq<sub>c*b</sub></br>

#### Output

1. \_F\_ file  
    Contains only the value of the function in the specified point. 
2. \_J\_ file  
     v<sub>1</sub> ... v<sub>n</sub>      where v<sub>i</sub> are components of the objective gradient.

