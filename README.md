# ADBench - autodiff benchmarks

This project aims to provide a running-time comparison for different tools for automatic differentiation, 
as described in https://arxiv.org/abs/1807.10129, (source in [Documentation/ms.tex](Documentation/ms.tex)).
It outputs a set of relevant graphs (see [Graph Archive](#graph-archive)).

For information about the layout of the project, see [Development](docs/Development.md#structure-of-the-repository).

For information about the current status of the project, see [Status](/STATUS.md).

## Methodology

For explanations on how do we perform the benchmarking see [Benchmarking Methodology](docs/Methodology.md), [Jacobian Correctness Verification](docs/JacobianCheck.md).

## Build and Run

The easiest way to build and run the benchmarks is to [use Docker](docs/Docker.md). If that doesn't work for you, please, refer to our [build and run guide](docs/BuildAndTest.md).

## Plot Results

Use `ADBench/plot_graphs.py` script to plot graphs of the resulting timings.

```bash
python ADBench/plot_graphs.py --save
```
This will save graphs as .png files to `tmp/graphs/static/`

Refer to [PlotCreating](docs/PlotCreating.md) for other possible command line arguments and the complete documentation.

## Graph Archive

From time to time we run the benchmarks and publish the resulting plots here:
https://adbenchwebviewer.azurewebsites.net/

The cloud infrastructure that generates these plots is described [here](docs/AzureBatch.md).

## Contributing

Contributions to fix bugs, test on new systems or add new tools are welcomed. See [Contributing](/CONTRIBUTING.md) for details on how to add new tools, and [Issues](/ISSUES.md) for known bugs and TODOs.

## Known Issues

See [Issues](/ISSUES.md) for a list of some of the known problems and TODOs.

There's [GitHub's issue](https://github.com/awf/ADBench/issues) page as well.
