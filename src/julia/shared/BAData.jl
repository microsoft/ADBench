module BAData

export BAInput, BASparseMatrix, BAOutput, insert_reproj_err_block!, insert_w_err_block!, empty_ba_output

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
    cams::Vector{Float64}
    X::Vector{Float64}
    w::Vector{Float64}
    obs::Vector{Float64}
    feats::Vector{Int}
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
    vals::Vector{Int}
    BASparseMatrix(n::Int, m::Int, p::Int) = new(n, m, p, 2 * p + p, N_CAM_PARAMS * n + 3 * m + p, [], [], [])
end

mutable struct BAOutput
    reproj_err::Vector{Float64}
    w_err::Vector{Float64}
    jacobian::BASparseMatrix
end

empty_ba_output() = BAOutput([], [], BASparseMatrix(0, 0, 0))

function insert_reproj_err_block!(matrix::BASparseMatrix, obsIdx::Int, camIdx::Int, ptIdx::Int, J::Vector{Float64})
    n_new_cols = N_CAM_PARAMS + 3 + 1
    lastrow = matrix.rows[end]
    push!(matrix.rows, lastrow + n_new_cols, lastrow + n_new_cols + n_new_cols)
    for i_row ∈ 1:2
        for i ∈ 1:N_CAM_PARAMS
            push!(matrix.cols, N_CAM_PARAMS * camIdx + i)
            push!(matrix.vals, J[2 * i + i_row])
        end
        col_offset = N_CAM_PARAMS * matrix.n
        val_offset = N_CAM_PARAMS * 2
        for i ∈ 1:3
            push!(matrix.cols, col_offset + 3 * ptIdx + i)
            push!(matrix.vals, J[val_offset + 2 * i + i_row])
        end
        col_offset += 3 * matrix.m
        val_offset += 3 * 2
        push!(matrix.cols, col_offset + obsIdx);
        push!(matrix.vals, J[val_offset + i_row]);
    end
end

function insert_w_err_block!(matrix::BASparseMatrix, wIdx::Int, w_d::Int)
    push!(matrix.rows, matrix.rows[end] + 1)
    push!(matrix.cols, N_CAM_PARAMS * matrix.n + 3 * matrix.m + wIdx)
    push!(matrix.vals, w_d)
end

end