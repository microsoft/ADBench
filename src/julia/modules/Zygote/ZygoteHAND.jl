module ZygoteHAND
include("../../shared/load.jl")
using ADPerfTest
using HandData
using Zygote
using LinearAlgebra

export get_hand_test

# objective
function angle_axis_to_rotation_matrix(angle_axis::Vector{Float64})::Matrix{Float64}
    n = sqrt(sum(abs2, angle_axis));
    if n < .0001
        return Matrix{Float64}(I, 3, 3)
    end
  
    x = angle_axis[1] / n
    y = angle_axis[2] / n
    z = angle_axis[3] / n
  
    s = sin(n)
    c = cos(n)
  
    [
        x*x+(1-x*x)*c x*y*(1-c)-z*s x*z*(1-c)+y*s;
        x*y*(1-c)+z*s y*y+(1-y*y)*c y*z*(1-c)-x*s;
        x*z*(1-c)-y*s z*y*(1-c)+x*s z*z+(1-z*z)*c
    ]
end

function apply_global_transform(pose_params::Vector{Vector{Float64}}, positions::Matrix{Float64})::Matrix{Float64}
    (angle_axis_to_rotation_matrix(pose_params[1]) .* pose_params[2]') * positions .+ pose_params[3]
end

function relatives_to_absolutes(relatives::Vector{Matrix{Float64}}, parents::Vector{Int})::Vector{Matrix{Float64}}
    # Zygote does not support array mutation and on every iteration we may need to access
    # random element created on one of the previous iterations, so, no way to rewrite this
    # as a comprehension. Hence looped vcat.
    absolutes = Vector{Matrix{Float64}}(undef, 0)
    for i=1:length(parents)
        if parents[i] == 0
            absolutes = vcat(absolutes, [ relatives[i] ])
        else
            absolutes = vcat(absolutes, [ absolutes[parents[i]] * relatives[i] ])
        end
    end
    absolutes
end

function euler_angles_to_rotation_matrix(xyz::Vector{Float64})::Matrix{Float64}
    tx = xyz[1]
    ty = xyz[2]
    tz = xyz[3]
    costx = cos(tx)
    sintx = sin(tx)
    costy = cos(ty)
    sinty = sin(ty)
    costz = cos(tz)
    sintz = sin(tz)
    # We could define this as a 3x3 matrix and then build a block-diagonal
    # 4x4 matrix with 1. at (4, 4), but Zygote couldn't differentiate
    # any way of building that I could come up with.
    Rx = [ 1. 0. 0. 0.; 0. costx -sintx 0.; 0. sintx costx 0.; 0. 0. 0. 1. ]
    Ry = [ costy 0. sinty 0.; 0. 1. 0. 0.; -sinty 0. costy 0.; 0. 0. 0. 1. ]
    Rz = [ costz -sintz 0. 0.; sintz costz 0. 0.; 0. 0. 1. 0.; 0. 0. 0. 1. ]
    Rz * Ry * Rx
end

function get_posed_relatives(model::HandModel, pose_params::Vector{Vector{Float64}})::Vector{Matrix{Float64}}
    # default parametrization xzy # Flexion, Abduction, Twist
    order = [1, 3, 2]
    offset = 3
    n_bones = size(model.bone_names, 1)
    [
        model.base_relatives[i_bone] * euler_angles_to_rotation_matrix(pose_params[i_bone + offset][order])
            for i_bone ∈ 1:n_bones
    ]
end

function get_skinned_vertex_positions(model::HandModel, pose_params::Vector{Vector{Float64}}, apply_global::Bool = true)::Matrix{Float64}
    relatives = get_posed_relatives(model, pose_params)
    absolutes = relatives_to_absolutes(relatives, model.parents)

    transforms = [ absolutes[i] * model.inverse_base_absolutes[i] for i ∈ 1:size(absolutes, 1) ]

    n_verts = size(model.base_positions, 2)
    positions = zeros(Float64, 3, n_verts)
    for i=1:size(transforms, 1)
        positions = positions +
            (transforms[i][1:3, :] * model.base_positions) .* model.weights[i, :]'
    end

    if model.is_mirrored
        positions = [-positions[1,:]'; positions[2:end, :]]
    end

    if apply_global
        positions = apply_global_transform(pose_params, positions)
    end
    positions
end

function to_pose_params(theta::Vector{Float64}, n_bones::Int)::Vector{Vector{Float64}}
    # to_pose_params !!!!!!!!!!!!!!! fixed order pose_params !!!!!
    #       1) global_rotation 2) scale 3) global_translation
    #       4) wrist
    #       5) thumb1, 6)thumb2, 7) thumb3, 8) thumb4
    #       similarly: index, middle, ring, pinky
    #       end) forearm
    
    n = 3 + n_bones
    n_fingers = 5
    cols = 5 + n_fingers * 4
    [
        if i == 1
            theta[1:3]
        elseif i == 2
            [1., 1., 1.]
        elseif i == 3
            theta[4:6]
        elseif i > cols || i == 4 || i % 4 == 1
            [0., 0., 0.]
        elseif i % 4 == 2
            [theta[i + 1], theta[i + 2], 0.]
        else
            [theta[i + 2], 0., 0.]
        end
            for i ∈ 1:n
    ]
end

function hand_objective_simple(model::HandModel, correspondences::Vector{Int}, points::Matrix{Float64}, theta::Vector{Float64})::Vector{Float64}
    pose_params = to_pose_params(theta, length(model.bone_names))
  
    vertex_positions = get_skinned_vertex_positions(model, pose_params)
  
    n_corr = length(correspondences)
    vcat([ points[:, i] - vertex_positions[:,correspondences[i]] for i ∈ 1:n_corr ]...)
end

mutable struct ZygoteHandContext
    input::Union{HandInput, Nothing}
    iscomplicated::Bool
    wrapper_hand_objective::Union{Function, Nothing}
    zygote_objective::Vector{Float64}
    zygote_jacobian_transposed::Matrix{Float64}
end

function zygote_hand_prepare!(ctx::ZygoteHandContext, input::HandInput)
    # Running Zygote.gradient with test input, because the first invocation
    # of gradient on a given function is very long.
    # Using test input ensures that all computations related to the actual input
    # are done in calculate_jacobian!

    ctx.input = input
    ctx.wrapper_hand_objective = theta -> hand_objective_simple(input.model, input.correspondences, input.points, theta)
end

function zygote_hand_calculate_objective!(ctx::ZygoteHandContext, times)
    for i in 1:times
        ctx.zygote_objective = hand_objective_simple(ctx.input.model, ctx.input.correspondences, ctx.input.points, ctx.input.theta)
    end
end

function zygote_hand_calculate_jacobian!(ctx::ZygoteHandContext, times)
    for i in 1:times
        y, back = Zygote.forward(ctx.wrapper_hand_objective, ctx.input.theta)
        ylen = size(y, 1)
        ctx.zygote_jacobian_transposed = hcat([ back(1:ylen .== i)[1] for i ∈ 1:ylen ]...)
    end
end

function zygote_hand_output!(out::HandOutput, ctx::ZygoteHandContext)
    out.objective = ctx.zygote_objective
    out.jacobian = ctx.zygote_jacobian_transposed'
end

get_hand_test() = Test{HandInput, HandOutput}(
    ZygoteHandContext(nothing, false, nothing, [], Matrix{Float64}(undef, 0, 0)),
    zygote_hand_prepare!,
    zygote_hand_calculate_objective!,
    zygote_hand_calculate_jacobian!,
    zygote_hand_output!
)

end