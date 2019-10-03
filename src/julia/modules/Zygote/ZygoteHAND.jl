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

function apply_global_transform(pose_params::Matrix{Float64}, positions::Matrix{Float64})::Matrix{Float64}
    # println(size((angle_axis_to_rotation_matrix(pose_params[:, 1]) .* pose_params[:, 2]') * positions))
    # println(size(pose_params[:, 3]))
    (angle_axis_to_rotation_matrix(pose_params[:, 1]) .* pose_params[:, 2]') * positions .+ pose_params[:, 3]
end

function relatives_to_absolutes(relatives::Array{Float64, 3}, parents::Vector{Int})::Array{Float64, 3}
    #cat([ parents[i] == 0 ? relatives[:, :, i] : [i] for i ∈ 1:length(parents) ]..., dims = 3)
    absolutes = Array{Float64, 3}(undef, size(relatives, 1), size(relatives, 2), 0)# zeros(eltype(relatives), size(relatives));
    for i=1:length(parents)
        if parents[i] == 0
            absolutes = cat(absolutes, relatives[:, :, i], dims = 3)
        else
            absolutes = cat(absolutes, absolutes[:, :, parents[i]] * relatives[:, :, i], dims = 3)
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
    Rx = [1. 0. 0.; 0. costx -sintx; 0. sintx costx]
    Ry = [costy 0. sinty; 0. 1. 0.; -sinty 0. costy]
    Rz = [costz -sintz 0.; sintz costz 0.; 0. 0. 1.]
    Rz * Ry * Rx
end

function get_posed_relatives(model::HandModel, pose_params::Matrix{Float64})::Array{Float64, 3}
    # default parametrization xzy # Flexion, Abduction, Twist
    order = [1, 3, 2]
    offset = 3
    n_bones = size(model.bone_names, 1)
    relatives = Array{Float64, 3}(undef, 4, 4, 0)
    
    for i_bone = 1:n_bones
        r = euler_angles_to_rotation_matrix(pose_params[order, i_bone + offset])
        T = [ r zeros(size(r, 1)); zeros(size(r, 2))' 1. ]
        #T = cat(euler_angles_to_rotation_matrix(pose_params[order, i_bone + offset]), [1], dims = (1, 2))
        relatives = cat(relatives, model.base_relatives[:, :, i_bone] * T, dims = 3)
    end
    relatives
end

function get_skinned_vertex_positions(model::HandModel, pose_params::Matrix{Float64}, apply_global::Bool = true)::Matrix{Float64}
    relatives = get_posed_relatives(model, pose_params)

    absolutes = relatives_to_absolutes(relatives, model.parents)

    transforms = cat([ absolutes[:, :, i] * model.inverse_base_absolutes[:, :, i] for i ∈ 1:size(absolutes, 3) ]..., dims = 3)

    n_verts = size(model.base_positions, 2)
    positions = zeros(Float64, 3, n_verts)
    # println("Positions:")
    # println(size(positions))
    # println("Base positions:")
    # println(size(model.base_positions))
    # println("trans * bp:")
    # println(size(transforms[1:3, :, 1] * model.base_positions))
    # println("Weights:")
    # println(size(model.weights[1, :]))
    for i=1:size(transforms, 3)
        positions = positions +
            (transforms[1:3, :, i] * model.base_positions) .* model.weights[i, :]'
    end

    if model.is_mirrored
        positions = [-positions[1,:]'; positions[2:end, :]]
    end

    if apply_global
        positions = apply_global_transform(pose_params, positions)
    end
    positions
end

function to_pose_params(theta::Vector{Float64}, n_bones::Int)::Matrix{Float64}
    # to_pose_params !!!!!!!!!!!!!!! fixed order pose_params !!!!!
    #       1) global_rotation 2) scale 3) global_translation
    #       4) wrist
    #       5) thumb1, 6)thumb2, 7) thumb3, 8) thumb4
    #       similarly: index, middle, ring, pinky
    #       end) forearm
    
    n = 3 + n_bones
    n_fingers = 5
    i_theta = 7
    hcat(
        theta[1:3], [1., 1., 1.], theta[4:6], [0. 0.; 0. 0.; 0. 0.;],
        [ 
            if i == 2
                (i_theta = i_theta + 2; [theta[i_theta - 2], theta[i_theta - 1], 0.])
            elseif i == 5
                [0., 0., 0.]
            else
                (i_theta = i_theta + 1; [theta[i_theta - 1], 0., 0.])
            end
                for finger = 1:n_fingers for i=2:5
        ]...#,
        #[ [0., 0., 0.] for i ∈ 21:n ]...
    )
    # pose_params = zeros(Float64, 3, n)
    
    # pose_params[:,1] = theta[1:3]
    # pose_params[:,2] = 1
    # pose_params[:,3] = theta[4:6]
    
    # i_theta = 7
    # i_pose_params = 6
    # n_fingers = 5
    # for finger = 1:n_fingers
    #     for i=2:4
    #         pose_params[1,i_pose_params] = theta[i_theta]
    #         i_theta = i_theta + 1
    #         if i==2
    #             pose_params[2,i_pose_params] = theta[i_theta]
    #             i_theta = i_theta + 1
    #         end
    #         i_pose_params = i_pose_params+1
    #     end
    #     i_pose_params = i_pose_params+1
    # end
    # pose_params
end

function hand_objective_simple(model::HandModel, correspondences::Vector{Int}, points::Matrix{Float64}, theta::Vector{Float64})::Vector{Float64}
    pose_params = to_pose_params(theta, length(model.bone_names))
    # Base.print_matrix(IOContext(stdout, :limit => false), pose_params)
    # println()
  
    vertex_positions = get_skinned_vertex_positions(model, pose_params)
  
    n_corr = length(correspondences)
    vcat([ points[:, i] - vertex_positions[:,correspondences[i]] for i ∈ 1:n_corr ]...)
    # err = zeros(eltype(theta),3, n_corr)
    # for i=1:n_corr
    #     err[:,i] = points[:,i] - vertex_positions[:,correspondences[i]]
    # end
    # err
end

mutable struct ZygoteHandContext
    input::Union{HandInput, Nothing}
    iscomplicated::Bool
    wrapper_hand_objective::Union{Function, Nothing}
    zygote_objective::Vector{Float64}
    zygote_jacobian
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
        ctx.zygote_jacobian = hcat([ back(1:ylen .== i) for i ∈ 1:ylen ]...)
    end
end

function zygote_hand_output!(out::HandOutput, ctx::ZygoteHandContext)
    out.objective = ctx.zygote_objective
    out.jacobian = ctx.zygote_jacobian
end

get_hand_test() = Test{HandInput, HandOutput}(
    ZygoteHandContext(nothing, false, nothing, [], Matrix{Float64}(undef, 0, 0)),
    zygote_hand_prepare!,
    zygote_hand_calculate_objective!,
    zygote_hand_calculate_jacobian!,
    zygote_hand_output!
)

end