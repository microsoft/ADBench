module DataUtils
include("../shared/load.jl")
using GMMData
using BAData
using HandData
using LSTMData
using Printf

export create_empty_output_for, save_output_to_file
export objective_file_name, jacobian_file_name, times_file_name, save_time_to_file, save_value_to_file, save_vector_to_file, save_matrix_to_file
export save_gmm_output_to_file

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
save_output_to_file(output::BAOutput, output_prefix::AbstractString, input_name::AbstractString, module_name::AbstractString) = save_ba_output_to_file(output, output_prefix, input_name, module_name)
save_output_to_file(output::LSTMOutput, output_prefix::AbstractString, input_name::AbstractString, module_name::AbstractString) = save_lstm_output_to_file(output, output_prefix, input_name, module_name)


format(x::Float64) = @sprintf "%.12g" x
format(x::Int) = @sprintf "%d" x

objective_file_name(output_prefix::AbstractString, input_name::AbstractString, module_name::AbstractString) = "$(output_prefix)$(input_name)_F_$(module_name).txt"
jacobian_file_name(output_prefix::AbstractString, input_name::AbstractString, module_name::AbstractString) = "$(output_prefix)$(input_name)_J_$(module_name).txt"
times_file_name(output_prefix::AbstractString, input_name::AbstractString, module_name::AbstractString) = "$(output_prefix)$(input_name)_times_$(module_name).txt"

function save_time_to_file(filepath::AbstractString, objective_time::Float64, derivative_time::Float64)
    open(filepath, "w") do io
        println(io, format(objective_time))
        print(io, format(derivative_time))
    end
end

function save_value_to_file(filepath::AbstractString, x::T) where T
    open(filepath, "w") do io
        print(io, format(x))
    end
end

function save_vector_to_file(filepath::AbstractString, v::Vector{T}) where T
    open(filepath, "w") do io
        for x ∈ v
            println(io, format(x))
        end
    end
end

function save_matrix_to_file(filepath::AbstractString, m::Matrix{T}) where T
    open(filepath, "w") do io
        for i ∈ 1:size(m, 1)
            join(io, map(j -> format(m[i, j]), 1:size(m, 2)), "\t")
            println(io)
        end
    end
end

function save_errors_to_file(filepath::AbstractString, reproj_err::Matrix{Float64}, w_err::Vector{Float64})
    open(filepath, "w") do io
        println(io, "Reprojection error:")
        for i ∈ reproj_err
            println(io, format(i))
        end
        println(io, "Zach weight error:")
        for i ∈ w_err
            println(io, format(i))
        end
    end
end

function save_sparse_j_to_file(filepath::AbstractString, jacobian::BASparseMatrix)
    open(filepath, "w") do io
        println(io, format(jacobian.nrows), " ", format(jacobian.ncols))
        println(io, format(size(jacobian.rows, 1)))
        join(io, map(format, jacobian.rows), " ")
        println(io)
        println(io, format(size(jacobian.cols, 1)))
        join(io, map(format, jacobian.cols), " ")
        println(io)
        join(io, map(format, jacobian.vals), " ")
    end
end

function save_gmm_output_to_file(output::GMMOutput, output_prefix::AbstractString, input_name::AbstractString, module_name::AbstractString)
    save_value_to_file(objective_file_name(output_prefix, input_name, module_name), output.objective)
    save_vector_to_file(jacobian_file_name(output_prefix, input_name, module_name), output.gradient)
end

function save_ba_output_to_file(output::BAOutput, output_prefix::AbstractString, input_name::AbstractString, module_name::AbstractString)
    save_errors_to_file(objective_file_name(output_prefix, input_name, module_name), output.reproj_err, output.w_err)
    save_sparse_j_to_file(jacobian_file_name(output_prefix, input_name, module_name), output.jacobian)
end

function save_lstm_output_to_file(output::LSTMOutput, output_prefix::AbstractString, input_name::AbstractString, module_name::AbstractString)
    save_value_to_file(objective_file_name(output_prefix, input_name, module_name), output.objective)
    save_vector_to_file(jacobian_file_name(output_prefix, input_name, module_name), output.gradient)
end

end