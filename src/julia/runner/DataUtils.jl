module DataUtils
include("../shared/load.jl")
using GMMData
using BAData
using HandData
using LSTMData

export create_empty_output_for, save_output_to_file

"""
    create_empty_output_for(input)

For given input object creates a corresponding empty output object.
"""
function create_empty_output_for end
create_empty_output_for(::GMMInput) = empty_gmm_output()
create_empty_output_for(::BAInput) = empty_ba_output()
create_empty_output_for(::HandInput) = empty_hand_output()
create_empty_output_for(::LSTMInput) = empty_lstm_output()

"""
    save_output_to_file(output, output_prefix, input_name, module_name)

Saves provided output to a correctly named file.
"""
function save_output_to_file end
save_output_to_file(output::GMMOutput, output_prefix::AbstractString, input_name::AbstractString, module_name::AbstractString) = save_gmm_output_to_file(output, output_prefix, input_name, module_name)

end