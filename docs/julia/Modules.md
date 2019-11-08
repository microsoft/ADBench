# Julia Modules

Modules on the Julia platform are Julia modules that export one or more factory functions for objects of type `Test{Input, Output}` exported by `ADPerfTest` module defined in `src/julia/shared/ADPerfTest.jl`.

## Adding new modules
1. Create a new folder `/src/julia/modules/YourModule/`.
1. For every objective you want to support create a file `src/julia/modules/YourModule/YourModuleT.jl` with the following content
    ```julia
    module YourModuleT
    # Adds modules in shared folder to LOAD_PATH
    include("../../shared/load.jl")
    using ADPerfTest
    using TData
    
    export get_t_test

    mutable struct YourModuleTContext
        # context definition
    end

    function yourmodule_t_prepare!(context::YourModuleTContext, input::TInput)
        # implementation
    end

    function yourmodule_t_calculate_objective!(context::YourModuleTContext, times)
        for i in 1:times
            # implementation
        end
    end

    function yourmodule_t_calculate_jacobian!(context::YourModuleTContext, times)
        for i in 1:times
            # implementation
        end
    end

    function yourmodule_t_output!(out::TOutput, context::YourModuleTContext)
        # implementation
    end

    get_t_test() = Test{TInput, TOutput}(
        YourModuleTContext(...),
        yourmodule_t_prepare!,
        yourmodule_t_calculate_objective!,
        yourmodule_t_calculate_jacobian!,
        yourmodule_t_output!
    )

    end
    ```
    Here `YourModule` is the name of your module in `PascalCase`, `yourmodule` - same in `all lowercase`, `T` is the capitalized short name of the objective (e.g. GMM, BA, one exception: `HAND` must be capitalized in the name of the file and the module, but written as `Hand` when it's a part of a name of a type, e.g. `HandInput`), and `t` is the short name of the objective in `all lowercase`. These are the expectations made by the [global runner](../GlobalRunner.md) and the plugin system implemented in [Julia runner](./Runner.md).

1. <span id="itest-implementation">Define the `YourModuleTContext` type and implement the functions. An object of the `YourModuleTContext` type will be used by the [Julia runner](./Runner.md) to preserve the state of the benchmark between calls to these functions.
    - ```julia
      function yourmodule_t_prepare!(context::YourModuleTContext, input::TInput)
      ```
        Converts the input data from the `TInput` type in which it is provided by
        the calling benchmark runner into the format optimized for use with the 
        tested AD framework.
        Stores it in the `context`.

        Optionally, performs other preparatory activities need by the tested AD framework.
    - ```julia 
      function yourmodule_t_calculate_objective!(context::YourModuleTContext, times)
      ``` 
        Repeatedly computes the objective function `times` times for the input
        stored in the `context`. Stores results in the `context`.
    - ```julia
      function yourmodule_t_calculate_jacobian!(context::YourModuleTContext, times)
      ```
        Repeatedly computes the Jacobian of the objective function `times` times
        for the input stored in the `context`. Stores results in the `context`.
    - ```julia
      function yourmodule_t_output!(out::TOutput, context::YourModuleTContext)
      ```
        Converts outputs saved in the `context` to the `TOutput` type.
    </span>

1. If your module uses any Julia packages, they should be added to the environment defined in the `JuliaProject.toml` in the root of the repository. Just activate that environment in the package manger console, before installing.
1. Add your module to common Julia module tests (see below).
1. Add your module to the [global runner script](../GlobalRunner.md).

## Unit Tests

### Adding tests for a new module

AD Bench already contains some tests for each objective.
When you add a new module, the first thing you should do is to test your module with the existing tests.
Follow these steps for every objective you want to test:

1. Open `/test/julia/modules/common/TTests.jl` where `T` is the short name of the tested objective.
   You will see the following lines:
    ```julia
    dir = @__DIR__
    t_test_implementations = Tuple{String, Float64}[
        ("$dir/../../../../src/julia/modules/Zygote/ZygoteT.jl", 1e-8),
        ...
    ]
    ```
1. Add your module and a `tolerance` for the test results to the list.
    ```julia
    dir = @__DIR__
    t_test_implementations = Tuple{String, Float64}[
        ("$dir/../../../../src/julia/modules/Zygote/ZygoteT.jl", 1e-8),
        ...
        ("$dir/../../../../src/julia/modules/YourModule/YourModuleT.jl", absoluteTolerance)
    ]
    ```

    `tolerance` is a number used to compare results produced by the current module with the correct results. If an absolute difference between at least one of them exceeds this value then the test is failed.

### Adding a new common test case

Follow these steps to add a new test case for an existing objective that will be shared by all modules:

1. Open `/test/julia/modules/common/TTests.jl` where `T` is the short name of the testing objective.
2. Find there
    ```julia
    @testset "T Module Test ($(basename(module_path)))"
    ```
3. In that test set there's a try-finally block that begins with
    ```julia
    test = TestLoader.get_t_test(module_name)
    ```
    Add your new test case to the end of the try block.

### Adding new objectives

To create a common test suite for a new objective create `/test/julia/modules/common/TTests.jl` with the following content:

```julia
module TTests

dir = @__DIR__
t_test_implementations = Tuple{String, Float64}[
    ("$dir/../../../../src/julia/modules/ModuleName1/ModuleName1T.jl", tolerance1),
    ...
]

map!(tup -> (abspath(tup[1]), tup[2]), t_test_implementations, t_test_implementations)

using Test
include("../../../../src/julia/shared/load.jl")
include("../../../../src/julia/runner/load.jl")
include("load.jl")
import ADPerfTest
import TestLoader
using TData
using TestUtils

@testset "T Module Tests" begin

@testset "T Module Test ($(basename(module_path)))" for (module_path, tolerance) in gmm_test_implementations
    module_dir, module_filename = splitdir(module_path)
    module_name, module_ext = splitext(module_filename)
    # Assert that the path to the module is correct
    ext_r = @test module_ext == ".jl"
    ispath_r = @test (ispath(module_path) && !isdir(module_path))
    if isa(ext_r, Test.Pass) && isa(ispath_r, Test.Pass)
        need_modify_load_path = !(module_dir ∈ LOAD_PATH)
        if need_modify_load_path
            push!(LOAD_PATH, module_dir)
        end
        try
            test = TestLoader.get_t_test(module_name)
            # Module loads
            @test isa(test, ADPerfTest.Test{TInput, TOutput})
            # Test cases go here
        finally
            pop!(LOAD_PATH)
        end
    end
end

end

end
```

This boilerplate code defines a test suite that will be shared by all modules listed in `t_test_implementations`. It includes loading the `ADPerfTest.Test{TInput, TOutput}` object into variable `test`.

Now you can add test cases with `@test` macro as usual.