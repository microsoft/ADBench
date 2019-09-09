module TestLoader
include("../shared/load.jl")
using ADPerfTest
using GMMData
using BAData
using HandData
using LSTMData

export get_gmm_test, get_ba_test, get_hand_test, get_lstm_test

module Box
end

loaded_modules = []

get_gmm_test(module_name::String)::Test{GMMInput, GMMOutput} = get_test("gmm", module_name)
get_ba_test(module_name::String)::Test{BAInput, BAOutput} = get_test("ba", module_name)
get_hand_test(module_name::String)::Test{HandInput, HandOutput} = get_test("hand", module_name)
get_lstm_test(module_name::String)::Test{LSTMInput, LSTMOutput} = get_test("lstm", module_name)

function get_test(test_name::String, module_name::String)
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