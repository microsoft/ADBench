# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

module GMMData
include("load.jl")

export Wishart, GMMInput, GMMOutput, empty_gmm_output, load_gmm_input

struct Wishart
    gamma::Float64
    m::Int
end

struct GMMInput
    alphas::Matrix{Float64}
    means::Matrix{Float64}
    icfs::Matrix{Float64}
    x::Matrix{Float64}
    wishart::Wishart
end

mutable struct GMMOutput
    objective::Float64
    gradient::Vector{Float64}
end

empty_gmm_output() = GMMOutput(0.0, [])

function load_gmm_input(fn::AbstractString, replicate_point::Bool)::GMMInput
    fid = open(fn)
    lines = readlines(fid)
    close(fid)
    line=split(lines[1], " ")
    d = parse(Int, line[1])
    k = parse(Int, line[2])
    n = parse(Int, line[3])
    icf_sz = div(d * (d + 1), 2)
    off = 1
  
    alphas = zeros(Float64, 1, k)
    for i in 1:k
        alphas[i] = parse(Float64, lines[i + off])
    end
    off += k
  
    means = zeros(Float64, d, k)
    for ik in 1:k
        line = split(lines[ik + off], " ")
        for id in 1:d
            means[id, ik] = parse(Float64, line[id])
        end
    end
    off += k
  
    icf = zeros(Float64, icf_sz, k)
    for ik in 1:k
        line = split(lines[ik + off], " ")
        for i in 1:icf_sz
            icf[i, ik] = parse(Float64, line[i])
        end
    end
    off += k
  
    if replicate_point
        x_ = zeros(Float64, d, 1)
        line = split(lines[1 + off], " ")
        for id in 1:d
            x_[id] = parse(Float64, line[id])
        end
        x = repeat(x_, 1, n)
        off += 1
    else
        x = zeros(Float64, d, n)
        for ix in 1:n
            line = split(lines[ix + off], " ")
            for id in 1:d
                x[id, ix] = parse(Float64, line[id])
            end
        end
        off += n
    end
    line = split(lines[1 + off]," ")
    wishart = Wishart(parse(Float64, line[1]), parse(Int, line[2]))
    GMMInput(alphas, means, icf, x, wishart)
end

end