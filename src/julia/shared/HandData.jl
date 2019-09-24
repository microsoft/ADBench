module HandData

export HandModel, HandInput, HandOutput, empty_hand_output

struct HandModel
    bone_names::Vector{String}
    parents::Vector{Int}
    base_relatives::Array{Float64,3}
    inverse_base_absolutes::Array{Float64,3}
    base_positions::Matrix{Float64}
    weights::Matrix{Float64}
    is_mirrored::Bool
end

struct HandInput
    model::HandModel
    correspondences::Vector{Int}
    points::Matrix{Float64}
    theta::Vector{Float64}
    "Is present only for 'complicated' kind of problems."
    us::Vector{Float64}
end

mutable struct HandOutput
    objective::Vector{Float64}
    jacobian::Matrix{Float64}
end

empty_hand_output() = HandOutput([], [])

end