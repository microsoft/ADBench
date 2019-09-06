module GMMData

export Wishart, GMMInput, GMMOutput, empty_gmm_output

struct Wishart
    gamma::Float64
    m::Int
end

struct GMMInput
    alphas::Vector{Float64}
    means::Vector{Float64}
    icfs::Vector{Float64}
    x::Vector{Float64}
    wishart::Wishart
end

mutable struct GMMOutput
    objective::Float64
    gradient::Vector{Float64}
end

empty_gmm_output() = GMMOutput(0.0, [])

end