module SaveUtils
using Printf

export objective_file_name, jacobian_file_name, times_file_name, save_time_to_file, save_value_to_file, save_vector_to_file, save_matrix_to_file

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
            join(io, map(1:size(m, 2), j -> format(m[i, j])), "\t")
            println(io)
        end
    end
end

end