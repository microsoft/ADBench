# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

module BAData

export BAInput, BASparseMatrix, BAOutput, insert_reproj_err_block!, insert_w_err_block!, empty_ba_output, load_ba_input,
    N_CAM_PARAMS, ROT_IDX, C_IDX, F_IDX, X0_IDX, RAD_IDX

const N_CAM_PARAMS = 11
const ROT_IDX = 1
const C_IDX = 4
const F_IDX = 7
const X0_IDX = 8
const RAD_IDX = 10

struct BAInput
    n::Int
    m::Int
    p::Int
    cams::Matrix{Float64}
    X::Matrix{Float64}
    w::Vector{Float64}
    feats::Matrix{Float64}
    obs::Matrix{Int}
end


struct BASparseMatrix
    "Number of cams"
    n::Int
    "Number of points"
    m::Int
    "Number of observations"
    p::Int
    nrows::Int
    ncols::Int
    """
    Int[nrows + 1]. Defined recursively as follows:
    rows[0] = 0
    rows[i] = rows[i-1] + the number of nonzero elements on the i-1 row of the matrix
    """
    rows::Vector{Int}
    "Column index in the matrix of each element of vals. Has the same size"
    cols::Vector{Int}
    "All the nonzero entries of the matrix in the left-to-right top-to-bottom order"
    vals::Vector{Float64}
    BASparseMatrix(n::Int, m::Int, p::Int) = new(n, m, p, 2 * p + p, N_CAM_PARAMS * n + 3 * m + p, [0], [], [])
end

mutable struct BAOutput
    reproj_err::Matrix{Float64}
    w_err::Vector{Float64}
    jacobian::BASparseMatrix
end

empty_ba_output() = BAOutput(Array{Float64}(undef, 0, 0), [], BASparseMatrix(0, 0, 0))

function insert_reproj_err_block!(matrix::BASparseMatrix, obsIdx::Int, camIdx::Int, ptIdx::Int, J::AbstractMatrix{Float64})
    # We use zero-based indexing for storage, but Julia uses 1-bsed indexing
    # Hence, the conversion
    obsIdxZeroBased = obsIdx - 1
    camIdxZeroBased = camIdx - 1
    ptIdxZeroBased = ptIdx - 1
    n_new_cols = N_CAM_PARAMS + 3 + 1
    lastrow = matrix.rows[end]
    push!(matrix.rows, lastrow + n_new_cols, lastrow + n_new_cols + n_new_cols)
    for i_row ∈ 1:2
        for i ∈ 1:N_CAM_PARAMS
            push!(matrix.cols, N_CAM_PARAMS * camIdxZeroBased + (i - 1))
            push!(matrix.vals, J[i_row, i])
        end
        col_offset = N_CAM_PARAMS * matrix.n
        for i ∈ 1:3
            push!(matrix.cols, col_offset + 3 * ptIdxZeroBased + (i - 1))
            push!(matrix.vals, J[i_row, N_CAM_PARAMS + i])
        end
        col_offset += 3 * matrix.m
        val_offset = N_CAM_PARAMS + 3
        push!(matrix.cols, col_offset + obsIdxZeroBased);
        push!(matrix.vals, J[i_row, val_offset + 1]);
    end
end

function insert_w_err_block!(matrix::BASparseMatrix, wIdx::Int, w_d::Float64)
    # We use zero-based indexing for storage, but Julia uses 1-bsed indexing
    # Hence, the conversion
    wIdxZeroBased = wIdx - 1
    push!(matrix.rows, matrix.rows[end] + 1)
    push!(matrix.cols, N_CAM_PARAMS * matrix.n + 3 * matrix.m + wIdxZeroBased)
    push!(matrix.vals, w_d)
end

function load_ba_input(fn::AbstractString)::BAInput
    fid = open(fn)
    lines = readlines(fid)
    close(fid)
    line=split(lines[1]," ")
    n = parse(Int,line[1])
    m = parse(Int,line[2])
    p = parse(Int,line[3])
    off = 2
  
    one_cam = zeros(Float64,N_CAM_PARAMS,1)
    line=split(lines[off]," ")
    for i in 1:N_CAM_PARAMS
        one_cam[i] = parse(Float64,line[i])
    end
    cams = repeat(one_cam,1,n)
    off += 1
  
    one_X = zeros(Float64,3,1)
    line=split(lines[off]," ")
    for i in 1:3
        one_X[i] = parse(Float64,line[i])
    end
    X = repeat(one_X,1,m)
    off += 1
  
    one_w = parse(Float64,lines[off])
    w = repeat([one_w],p)
    off += 1
  
    one_feat = zeros(Float64,2,1)
    line=split(lines[off]," ")
    for i in 1:2
        one_feat[i] = parse(Float64,line[i])
    end
    feats = repeat(one_feat,1,p)
  
    camIdx = 1
    ptIdx = 1
    obs = zeros(Int,2,p)
    for i in 1:p
        obs[1,i] = camIdx
        obs[2,i] = ptIdx
        camIdx = (camIdx%n) + 1
        ptIdx = (ptIdx%m) + 1
    end

    BAInput(n, m, p, cams, X, w, feats, obs)
end

end