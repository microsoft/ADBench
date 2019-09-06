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
    if !(module_name ∈ loaded_modules)
        include_string(Box, "$module_name = Module()\n")
    end
    usingstr = "using $module_name\n"
    module_symbol = Meta.parse("Box.$module_name")
    get_test_function_name = "get_$(test_name)_test"
    @eval include_string($module_symbol, $usingstr)
    if @eval !isdefined($module_symbol, Symbol($get_test_function_name))
        throw(ArgumentError("Module $module_name doesn't export a funtion $get_test_function_name."))
    end
    @eval Base.invokelatest($(Meta.parse("Box.$module_name.$get_test_function_name")))
end

end