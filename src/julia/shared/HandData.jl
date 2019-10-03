module HandData
using DelimitedFiles

export HandModel, HandInput, HandOutput, empty_hand_output, load_hand_input

struct HandModel
    bone_names::Vector{String}
    parents::Vector{Int}
    "Stacked along the 3rd dimension"
    base_relatives::Array{Float64,3}
    "Stacked along the 3rd dimension"
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
    us::Union{Matrix{Float64}, Nothing}
end

mutable struct HandOutput
    objective::Vector{Float64}
    jacobian::Matrix{Float64}
end

empty_hand_output() = HandOutput([], Matrix{Float64}(undef, 0, 0))

function load_hand_model(model_dir::AbstractString)::HandModel
    delimeter = ':'
    bones_fn = joinpath(model_dir, "bones.txt")
    A = readdlm(bones_fn, delimeter)

    n_bones = size(A, 1)
    bone_names = A[:, 1]
    parents = A[:, 2] .+ 1 #julia indexing

    transforms = A[:, 3:18]
    transforms = permutedims(reshape(transforms, (n_bones, 4, 4)), (3, 2, 1))

    inverse_absolute_transforms  = A[:, 19:34]
    inverse_absolute_transforms = permutedims(reshape(inverse_absolute_transforms, (n_bones, 4, 4)), (3, 2, 1));

    vertices_fn = joinpath(model_dir, "vertices.txt")
    A = readdlm(vertices_fn, delimeter);

    base_positions = A[:, 1:3]';
    n_vertices = size(A, 1);

    weights = zeros(Float64, n_bones, n_vertices);
    for i_vert = 1:n_vertices
        for i=0:A[i_vert, 9]-1
            i_bone = A[i_vert, 9 + i * 2 + 1] + 1; #julia indexing
            weights[i_bone, i_vert] = A[i_vert, 9 + i * 2 + 2];
        end
    end

    HandModel(
        bone_names,
        parents,
        transforms,
        inverse_absolute_transforms,
        [base_positions; ones(Float64, 1, size(base_positions, 2))],
        weights,
        false
    )
end

function load_hand_input(fn::AbstractString, iscomplicated::Bool)::HandInput
    modeldir = joinpath(dirname(fn), "model")
    model = load_hand_model(modeldir)
    open(fn) do io
        line = split(readline(io), " ")
        n_pts = parse(Int, line[1])
        n_theta = parse(Int, line[2])
        
        corrs = Vector{Int}(undef, n_pts)
        pts = Matrix{Float64}(undef, 3, n_pts)
        for i in 1:n_pts
            line = split(readline(io), " ")
            corrs[i] = parse(Int, line[1]) + 1 #julia indexing
            for j in 1:3
                pts[j, i] = parse(Float64, line[j + 1])
            end
        end

        if iscomplicated
            us = hcat([parse.(Float64, split(readline(io), " ")) for i=1:n_pts]...)
        else
            us = nothing
        end

        theta = [parse(Float64, readline(io)) for i=1:n_theta]

        return HandInput(model, corrs, pts, theta, us)
    end
end

end