# Shorthand type names
typealias Vec Vector{Float64}
typealias Mat Matrix{Float64}
typealias SymMat Symmetric{Float64,Matrix{Float64}}

# Utility functions
AAt(A::Mat) = Symmetric(A*A')
AtA(A::Mat) = Symmetric(A'*A)

# sumsq
sumsq(x::Vec) = norm(x)^2
