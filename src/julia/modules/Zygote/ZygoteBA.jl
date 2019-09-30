module ZygoteBA
include("../../shared/load.jl")
using ADPerfTest
using BAData

using Zygote
using Printf
using LinearAlgebra

export get_ba_test

##################### objective #############################

function rodrigues_rotate_point(rot :: Vector{T}, X :: Vector{T}) where T
    sqtheta = sum(rot .* rot)
    if sqtheta > 1e-10
        theta = sqrt(sqtheta)
        costheta = cos(theta)
        sintheta = sin(theta)
        theta_inverse = 1. / theta

        w = theta_inverse * rot
        w_cross_X = cross(w, X)
        tmp = dot(w, X) * (1. - costheta)

        X * costheta + w_cross_X * sintheta + w * tmp
    else
        X + cross(rot, X)
    end
end

function radial_distort(rad_params, proj)
    rsq = sum(proj .* proj)
    L = 1. + rad_params[1] * rsq + rad_params[2] * rsq * rsq
    proj * L
end

function project(cam, X)
    Xcam = rodrigues_rotate_point(cam[ROT_IDX:ROT_IDX+2], X - cam[C_IDX:C_IDX+2])
    distorted = radial_distort(cam[RAD_IDX:RAD_IDX+1], Xcam[1:2] / Xcam[3])
    distorted * cam[F_IDX] + cam[X0_IDX:X0_IDX+1]
end

function compute_reproj_err(cam, X, w, feat)
    w * (project(cam, X) - feat)
end

function ba_objective(cams, X, w, obs, feats)
    reproj_err = similar(feats)
    for i in 1:size(feats, 2)
        reproj_err[:, i] = compute_reproj_err(cams[:, obs[1, i]], X[:, obs[2, i]], w[i], feats[:, i])
    end
    w_err = 1.0 .- w .* w
    (reproj_err, w_err)
end

#################### derivatives extra ##########################

function pack(cam, X, w)
    [cam[:]; X[:]; w]
end

function unpack(packed)
    packed[1:end-4], packed[end-3:end-1], packed[end]
end

function compute_w_err(w)
    1.0 - w * w
end

compute_w_err_d = x -> Zygote.gradient(compute_w_err, x)[1]

function compute_reproj_err_d(params, feat)
    cam, X, w = unpack(params)
    compute_reproj_err(cam, X, w, feat)
end

function compute_ba_J(cams, X, w, obs, feats)
    n = size(cams, 2)
    m = size(X, 2)
    p = size(obs, 2)
    jacobian = BASparseMatrix(n, m, p)
    reproj_err_d = zeros(2 * p, N_CAM_PARAMS + 3 + 1)
    for i in 1:p
        compute_reproj_err_d_i = x -> compute_reproj_err_d(x, feats[:, i])
        camIdx =  obs[1, i]
        ptIdx = obs[2, i]
        _, J = Zygote.forward_jacobian(compute_reproj_err_d_i, pack(cams[:, camIdx], X[:, ptIdx], w[i]))
        insert_reproj_err_block!(jacobian, i, camIdx, ptIdx, J')
    end
    for i in 1:p
        w_err_d_i = compute_w_err_d(w[i])
        insert_w_err_block!(jacobian, i, w_err_d_i)
    end
    jacobian
end

mutable struct ZygoteBAContext
    input::Union{BAInput, Nothing}
    reproj_err::Matrix{Float64}
    w_err::Vector{Float64}
    jacobian::BASparseMatrix
end

function zygote_ba_prepare!(ctx::ZygoteBAContext, input::BAInput)
    # Running Zygote.gradient with test input, because the first invocation
    # of gradient on a given function is very long.
    # Using test input ensures that all computations related to the actual input
    # are done in calculate_jacobian!
    testinput = load_ba_input("$(@__DIR__)/../../../../data/ba/test.txt")
    compute_reproj_err_d_1 = x -> compute_reproj_err_d(x, testinput.feats[:, 1])
    Zygote.forward_jacobian(compute_reproj_err_d_1, pack(testinput.cams[:, testinput.obs[1, 1]], testinput.X[:, testinput.obs[2, 1]], testinput.w[1]))
    Zygote.gradient(compute_w_err, 1.0)
    
    ctx.input = input
end

function zygote_ba_calculate_objective!(ctx::ZygoteBAContext, times)
    for i in 1:times
        ctx.reproj_err, ctx.w_err = ba_objective(ctx.input.cams, ctx.input.X, ctx.input.w, ctx.input.obs, ctx.input.feats)
    end
end

function zygote_ba_calculate_jacobian!(ctx::ZygoteBAContext, times)
    for i in 1:times
        ctx.jacobian = compute_ba_J(ctx.input.cams, ctx.input.X, ctx.input.w, ctx.input.obs, ctx.input.feats)
    end
end

function zygote_ba_output!(out::BAOutput, ctx::ZygoteBAContext)
    out.reproj_err = ctx.reproj_err
    out.w_err = ctx.w_err
    out.jacobian = ctx.jacobian
end

get_ba_test() = Test{BAInput, BAOutput}(
    ZygoteBAContext(nothing, Array{Float64}(undef, 0, 0), [], BASparseMatrix(0, 0, 0)),
    zygote_ba_prepare!,
    zygote_ba_calculate_objective!,
    zygote_ba_calculate_jacobian!,
    zygote_ba_output!
)

end