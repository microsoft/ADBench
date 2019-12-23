# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

module TestLoader
include("../shared/load.jl")
using ADPerfTest
using GMMData
using BAData
using HandData
using LSTMData

export get_gmm_test, get_ba_test, get_hand_test, get_lstm_test, get_test_for

module Box
end

loaded_modules = []

"""
    get_gmm_test(module_name)

Loads a `Test{GMMInput, GMMOutput}` object from the module `module_name`.

Callbacks of this object will be created in a world newer than the current one and as such will have to be
invoked via `Base.invokelatest`.
"""
get_gmm_test(module_name::AbstractString)::Test{GMMInput, GMMOutput} = get_test("gmm", module_name)

"""
    get_ba_test(module_name)

Loads a `Test{BAInput, BAOutput}` object from the module `module_name`.

Callbacks of this object will be created in a world newer than the current one and as such will have to be
invoked via `Base.invokelatest`.
"""
get_ba_test(module_name::AbstractString)::Test{BAInput, BAOutput} = get_test("ba", module_name)

"""
    get_hand_test(module_name)

Loads a `Test{HandInput, HandOutput}` object from the module `module_name`.

Callbacks of this object will be created in a world newer than the current one and as such will have to be
invoked via `Base.invokelatest`.
"""
get_hand_test(module_name::AbstractString)::Test{HandInput, HandOutput} = get_test("hand", module_name)

"""
    get_lstm_test(module_name)

Loads a `Test{LSTMInput, LSTMOutput}` object from the module `module_name`.

Callbacks of this object will be created in a world newer than the current one and as such will have to be
invoked via `Base.invokelatest`.
"""
get_lstm_test(module_name::AbstractString)::Test{LSTMInput, LSTMOutput} = get_test("lstm", module_name)

"""
    get_test_for(input, output, module_name)

Loads a `Test{Input, Output}` object appropriate for provided `input` and `output` from the module `module_name`.

Callbacks of this object will be created in a world newer than the current one and as such will have to be
invoked via `Base.invokelatest`.
"""
function get_test_for end
get_test_for(input::GMMInput, output::GMMOutput, module_name::AbstractString)::Test{GMMInput, GMMOutput} = get_gmm_test(module_name)
get_test_for(input::BAInput, output::BAOutput, module_name::AbstractString)::Test{BAInput, BAOutput} = get_ba_test(module_name)
get_test_for(input::HandInput, output::HandOutput, module_name::AbstractString)::Test{HandInput, HandOutput} = get_hand_test(module_name)
get_test_for(input::LSTMInput, output::LSTMOutput, module_name::AbstractString)::Test{LSTMInput, LSTMOutput} = get_lstm_test(module_name)

"""
    get_test(test_name, module_name)

Loads a `Test{Input, Output}` object appropriate for `test_name` objective from the module `module_name`.

Callbacks of this object will be created in a world newer than the current one and as such will have to be
invoked via `Base.invokelatest`.

Dynamically loads module `module_name` into an isolated environment if necessary and calls
`get_\$(test_name)_test()::Test{Input, Output}` that it is expected to export.
"""
function get_test(test_name::AbstractString, module_name::AbstractString)
    box_module_name = module_name * "Box"
    if !(module_name ∈ loaded_modules)
        # Creating a new submodule coorespondig to the module being loaded
        @eval(Box, $(Symbol(box_module_name)) = Module())
        # "using" the module being loaded in the new submodule
        @eval(Box, @eval($(Symbol(box_module_name)), using $(Symbol(module_name))))
        push!(loaded_modules, module_name)
    end
    get_test_function_name = "get_$(test_name)_test"
    # Checking that the submodule that uses the target module has a test factory function defined
    if @eval !isdefined($(Meta.parse("Box.$box_module_name")), Symbol($get_test_function_name))
        throw(ArgumentError("Module $module_name doesn't export a funtion $get_test_function_name."))
    end
    # Evaluating test factory function that we imported ("used") from the module $module_name
    # into submodule Box.$box_module_name
    @eval Base.invokelatest($(Meta.parse("Box.$box_module_name.$get_test_function_name")))
end

end