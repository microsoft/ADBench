# ADBench Architecture

## Overview

On the highest level ADBench consists of
- Global runner
- Benchmark runners
- Automatic differentiation (AD) framework testing modules
- Result-processing scripts

_Testing modules_ here are modules in terms of the platform they are developed for (e.g shared objects for C++, assemblies for .NET (Core), `.py` files in Python) that perform AD using the frameworks being tested.

_Benchmark runners_ are console applications that load _testing modules_ and input data and measure the time modules take to compute the objective function and its considered derivative for the loaded input data. Then it writes measured times and computed derivatives to files with standardized names. We have one benchmark runner per development platform, so that we can use the same time measuring code for all frameworks supporting that platform.

_Global runner_ is a script that is aware of all existing _benchmark runners_, _testing modules_, and sets of input parameters for the objective functions. It consequitively runs all benchmarks using corresponding _benchmark runners_ while enforcing specified hard time limits.

_Result-processing scripts_ are scripts that consume the outputs of _benchmark runners_ and
- Check the accuracy of computated objective functions and derivatives
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