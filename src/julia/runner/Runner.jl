module Runner
include("load.jl")
include("../shared/load.jl")
using ADPerfTest
using GMMData
using BAData
using HandData
using LSTMData
using Benchmark

test_type = lowercase(ARGS[1])
module_path = ARGS[2]
input_filepath = ARGS[3]
output_prefix = ARGS[4]
minimum_measurable_time = parse(Float64, ARGS[5])
nruns_f = parse(Int,ARGS[6])
nruns_J = parse(Int,ARGS[7])
time_limit = parse(Float64, ARGS[8])
replicate_point = size(ARGS,1) >= 9 && ARGS[9] == "-rep"

if !ispath(module_path) || isdir(module_path)
    throw(ArgumentError("File $module_path does not exist."))
end
if !endswith(module_path, ".jl")
    throw(ArgumentError("File $module_path is expected to be a Julia module and end with '.jl'."))
end
if !ispath(input_filepath) || isdir(input_filepath)
    throw(ArgumentError("File $input_filepath does not exist."))
end

module_abs_path = abspath(module_path)
module_dir = dirname(module_abs_path)
module_name = basename(module_path)[1:end - 3]
if !(module_dir ∈ LOAD_PATH)
    push!(LOAD_PATH, module_dir)
end

input_filename = basename(input_filepath)
lastdot = findlast(".", input_filename)
if (lastdot === nothing)
    input_name = input_filename
else
    input_name = input_filename[1:first(lastdot) - 1]
end


if test_type == "gmm"
    input = load_gmm_input(input_filepath, replicate_point)
    module_display_name = module_name[1:end - 3]
elseif test_type == "ba"
    input = load_ba_input(input_filepath)
    module_display_name = module_name[1:end - 2]
elseif test_type == "lstm"
    input = load_lstm_input(input_filepath)
    module_display_name = module_name[1:end - 4]
else
    throw(ArgumentError("Julia runner doesn't support tests of $test_type type."))
end

run_benchmark(input, input_name, module_name, output_prefix, module_display_name, minimum_measurable_time, nruns_f, nruns_J, time_limit)

end