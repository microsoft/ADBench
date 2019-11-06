# ADBench Architecture

## Overview

On the highest level ADBench consists of
- Global runner
- Benchmark runners
- Automatic differentiation (AD) framework testing modules
- Result-processing scripts

_Testing modules_ here are modules in terms of the platform they are developed for (e.g shared objects for C++, assemblies for .NET (Core), `.py` files in Python) that perform AD using the frameworks being tested.

_Benchmark runners_ are console applications that load _testing modules_ and input data and measure the time modules take to compute the objective function and its considered derivative for the loaded input data. Then they write measured times and computed derivatives to files with standardized names. We have one benchmark runner per development platform, so that we can use the same time-measuring code for all frameworks supporting that platform.

_Global runner_ is a script that is aware of all existing _benchmark runners_, _testing modules_, and sets of input parameters for the objective functions. It consecutively runs all benchmarks using corresponding _benchmark runners_ while enforcing specified hard time limits.

_Result-processing scripts_ are scripts that consume the outputs of _benchmark runners_ and
- Check the accuracy of computed objective functions and derivatives
- Create visualizations

<table>
  <tr>
    <td>manual</td>
    <td>manual (eigen)</td>
    <td>finite</td>
    <td>...</td>
    <td>Autograd</td>
    <td>PyTorch</td>
    <td>Tensorflow</td>
    <td>...</td>
    <td>DiffSharp</td>
    <td>...</td>
    <td>Zygote</td>
    <td>...</td>
  </tr>
  <tr>
    <td colspan="4">C++ runner</td>
    <td colspan="4">Python runner</td>
    <td colspan="2">.NET runner</td>
    <td colspan="2">Julia runner</td>
  </tr>
  <tr>
    <td colspan="12">Global runner</td>
  </tr>
</table>

## Interfaces

### Testing Modules

As mentioned above, _testing modules_ are modules in terms of the platform they are developed for. Their responsibility is to repeatedly compute the objective function or perform AD using the tested framework. They do not perform any I/O or time measurements - those are responsibilities of the _benchmark runners_.

Their interfaces are defined strictly within the specifications of the corresponding runners, but generally would contain functions for
- Converting the input data from the format in which it is provided by the calling benchmark runner into the format optimized for use with the tested AD framework
- Repeatedly computing one of the objective functions given number of times, saving results into a pre-allocated internal structure optimized for use with the tested AD framework
- Repeatedly computing a derivative of one of the objective functions given number of times, saving results into a pre-allocated internal structure optimized for use with the tested AD framework
- Converting internally saved outputs into the format specified by the runner

### Benchmark Runners

_Benchmark runners_ are console applications that load _testing modules_ and input data and measure the time modules take to compute the objective function and its considered derivative for the loaded input data. Time measurement is performed according to the [methodology](Methodology.md). _Benchmark runners_ are started by the _global runner_. They write measured times and computed derivatives to files, that are then read by the _result-processing scripts_.

Interfaces for interacting with the _testing modules_ are specific to each runner and, therefore, described in the specifications for the runners. The broad description is given in the section regarding [_testing modules_](#testing-modules).

_Global runner_ tells _benchmark runners_ which _testing module_ to use, which test to run, etc. via command-line arguments. The exact invocation specifications are specific to the _benchmark runners_ and known to the _global runner_. Generally, the arguments would include
- path to the _testing module_
- path to the input data
- path to the folder where the output should be saved
- name of the objective function
- some of the variables listed in the [methodology](Methodology.md)

_Benchmark runners_ output 3 files into the folder specified by the _global runner_. These files are
- `<name of the input>_times_<name of the testing module>.txt` - new line-separated timings for the computation of the objective function and the derivative.
- `<name of the input>_F_<name of the testing module>.txt` - new line-separated values of the objective function computed by the module.
- `<name of the input>_J_<name of the testing module>.txt` - values of the derivative computed by the module. Exact format is specific to the objective function. See [FileFormat](./FileFormat.md) for details.

### Global Runner

_Global runner_ is a script that runs all benchmarks using corresponding _benchmark runners_ while enforcing specified hard time limits.
It contains code for starting all the _benchmark runners_ and is aware of all existing _testing modules_.

_Global runner_ is started by the user. User may pass some or all of the variables listed in the [methodology](Methodology.md) as command line arguments.

For the complete documentation refer to [GlobalRunner.md](./GlobalRunner.md).

### Result-Processing Scripts

Two scripts. One looks at the output files and compares the results in them to the manually computed correct ones, the other produces visualizations of the timings.

__The exact specifications are to be developed along with the _result-processing scripts_ themselves__.
