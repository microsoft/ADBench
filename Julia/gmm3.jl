using Base.Test
using ReverseDiffSource

@printf("*********************\njulia version = %s, dir %s\n", Base.VERSION_STRING, pwd())

typealias Vec Vector{Float64}
typealias Mat Matrix{Float64}
typealias SymMat Symmetric{Float64,Matrix{Float64}}

AAt(A::Mat) = Symmetric(A*A')
AtA(A::Mat) = Symmetric(A'*A)
sumsq(x::Vec) = norm(x)^2

# Make matrix from diagonal and strict lower triangle,
# e.g. D = [d11 d22 d33 d44]
#      LT = [L21 L31 L32 L41 L42 L43]
# Outputting
#  [d11   0   0   0]
#  [L21 d12   0   0] # row r: Ls starting at sum_i=1^r
#  [L31 L32 d33   0]
#  [L41 L42 L43 d44]
function ltri_unpack(D::Vec, LT::Vec)
  d=length(D)
  make_row(r::Int, L) = hcat(reshape([ L[i] for i=1:r-1 ],1,r-1), D[r], zeros(1,d-r))
  row_start(r::Int) = div((r-1)*(r-2),2)
  inds(r) = row_start(r)+(1:r-1)
  vcat([ make_row(r, LT[inds(r)]) for r=1:d ]...)
end

ltri_unpack(D, L) = ltri_unpack([Float64(d) for d in D], [Float64(l) for l in L])

@test [11 0 0 0; 21 22 0 0 ; 31 32 33 0 ; 41 42 43 44] == ltri_unpack([11 22 33 44], [21 31 32 41 42 43])

LL = ltri_unpack([1 2 3 4], [21 31 32 41 42 43])
@printf("An example lower triangle made from diag and LT=\n%s\n", LL)

function ltri_pack{M<:AbstractMatrix}(L::M)
  d=size(L,1)

  make_row(r::Int, L) = hcat(reshape([ L[i] for i=1:r-1 ],1,r-1), D[r], zeros(1,d-r))
  row_start(r::Int) = (r-1)*(r-2)/2
  diag(L), hcat([L[r,1:r-1] for r=1:d ]...)
end

ltri_pack{T}(L::LowerTriangular{T, Matrix{T}}) = ltri_pack(full(L)) ## Until  packed storage is implemented for those

@test ltri_unpack(ltri_pack(LL)...) == LL

@printf("pak=%s\n", ltri_pack(LL))

# Conventional GMM.
# This doesn't even use inverse covariance, because as soon as you
# start down that route, you may as well go for lpGMM below.
type GMM
  n::Int           # number of Gaussians
  d::Int           # dimension of Gaussian
  alphas::Vec      # weights: n, require sum(alphas)==1
  mus::Array{Vec}  # means: n, each dx1
  sigmas::Array{SymMat}  # covariances: n, each dxd symmetric positive definite
end


function log_likelihood(g::GMM, x::Vec)
  total = 0
  for k=1:g.n
    mean = g.mus[k]
    weight =  g.alphas[k]
    Σ = g.sigmas[k]
    mahalanobis = dot(mean - x, inv(Σ) * (mean - x))
    @printf("m=%s, ", det(inv(full(Σ))))
    total += weight / sqrt(det(2pi*full(Σ))) * exp(-0.5*mahalanobis)
  end
  @printf("w=%f\n", total)
  log(total)
end

n=3
d=2
alphas=rand(n); alphas /= sum(alphas);
mus=[randn(d) for k=1:n]
sigmas=[AAt(randn(d,d)) for k=1:n]
test_gmm = GMM(n,d,alphas,mus,sigmas)
@printf("An example gmm = %s\n", test_gmm)

x = randn(d) # Test point

ll0 = log_likelihood(test_gmm, x)
@printf("ll0=%f\n", ll0)

##########################################################################
# Log-parametrized GMM.
# Weights are strictly positive, covariances are parameterized by their inverse
# square roots (lower triangular).
type lpGMM
  n::Int           # number of Gaussians
  d::Int           # dimension of Gaussian
  alphas::Vec      # log weights: n
  mus::Array{Vec}  # means: n, each dx1
  LDs::Array{Vec}  # square-root-inverse-covariances, log(diagonal): n, each d x 1
  LTs::Array{Vec}  # square-root-inverse-covariances, lower triangle: n, each d*(d-1)/2 x 1
end

# Convert simple GMM to lpGMM
function lpGMM(g::GMM)
  LTs = Array{Vec}(g.n)
  LDs = Array{Vec}(g.n)
  for k=1:g.n
    L = inv(chol(g.sigmas[k].data, Val{:L}))
    D, T = ltri_pack(L)
    LDs[k], LTs[k] = vec(log(D)), vec(T)
  end
  lpGMM(g.n,g.d,log(g.alphas),g.mus,LDs,LTs)
end

# Convert log-parameterized-GMM to simple GMM UnivariateGMM
function GMM(l::lpGMM)
  alphas::Vec = exp(l.alphas)/sum(exp(l.alphas))
  mus::Array{Vec} = l.mus
  Ls = [ltri_unpack(exp(l.LDs[i]), l.LTs[i]) for i=1:l.n]
  sigmas::Array{SymMat} = map(A->inv(Symmetric(A'*A)), Ls)
  GMM(l.n,l.d,alphas,mus,sigmas)
end

g = lpGMM(test_gmm)

#@printf("gmm=%s\n**\n", GMM(g))

########################################

const halflog2π = log(2π)/2

function log_likelihood(g::lpGMM, x::Vec)
  total = 0
  weight_normalizer = sum(exp(g.alphas))
  for k=1:g.n
    InvLowerTriangle = ltri_unpack(exp(g.LDs[k]), g.LTs[k])
    mean = g.mus[k]
    weight =  exp(g.alphas[k])/weight_normalizer # Weights parametrized as logs
    mahalanobis = sumsq(InvLowerTriangle * (mean - x))
    @printf("m=%s, ", det(InvLowerTriangle'*InvLowerTriangle))
    total += weight * det(InvLowerTriangle) * exp(-0.5*mahalanobis)
  end
  @printf("tot=%f, ", total)
  log(total) - halflog2π*g.d
end

ll1 = log_likelihood(g, x)
@printf("ll0=%f, ll1=%f, rat=%f\n", ll0, ll1, ll0/ll1)
@test_approx_eq_eps ll0 ll1 1e-12

########################################
## A better implementation, with some factorizing and logsumexp:

# logsumexp()
function logsumexp_both(x::Array{Float64,1})
  A = maximum(x);
  ema = exp(x-A);
  sema = sum(ema);
  l = log(sema) + A;
  Jacobian = ema/sema;
  return (l, Jacobian);
end
logsumexp(x::Array{Float64,1}) = logsumexp_both(x)[1]
r = rand(5);
@test_approx_eq_eps logsumexp(r) log(sum(exp(r))) 1.0e-8

@deriv_rule logsumexp(x::AbstractArray)  x  logsumexp_both(x)[2].*ds

function logsumexp_1st(x::Array{Float64,1})
  A = maximum(x);
  ema = exp(x-A);
  sema = sum(ema);
  log(sema) + A;
end
rdiff(logsumexp_1st, (zeros(3),)).code


mahal(L::Mat, mu::Vec, x::Vec) = sumsq(L*(x-mu))

function log_likelihood_2(g::lpGMM, x::Vec)

  d_mahal = [0.5*mahal(ltri_unpack(exp(g.LDs[i]), g.LTs[i]), g.mus[i], x) for i in 1:g.n]

  determinants = [sum(g.LDs[i]) for i in 1:g.n]

  logsumexp(g.alphas + determinants - d_mahal) - logsumexp(g.alphas) - halflog2π*g.d
end

ll2 = log_likelihood_2(g, x)
@printf("ll0=%f, ll2=%f, rat=%f\n", ll0, ll2, ll0/ll2)
@test_approx_eq_eps ll0 ll2 1e-12

# Matrix version, in case needed
function log_likelihood_mat(alphas::Vec, mus::Mat, LDs::Mat, LTs::Mat, x::Vec)
  n = length(alphas)
  d = size(mus,1)
  L(i::Int) = ltri_unpack(exp(LDs[:,i]), LTs[:,i])
  d_mahal = [0.5*mahal(L(i), mus[:,i], x) for i in 1:n]

  determinants = [sum(LDs[:,i]) for i in 1:n]

  logsumexp(alphas + determinants - d_mahal) - logsumexp(alphas) - halflog2π*d
end

ll3 = log_likelihood_mat(g.alphas, hcat(g.mus...), hcat(g.LDs...), hcat(g.LTs...), x)
@printf("ll0=%f, ll3=%f, rat=%f\n", ll0, ll3, ll0/ll3)


using Stats
using Distributions


function draw(g::GMM)
  rng = Distributions.Categorical(exp(alphas)/sum(exp(alphas)))
  k = rand(rng)
  rng = Distributions.MultivariateNormal(mus[k], make_L(exp(g.LDs[k]), g.LTs[k]))
  x::Vec = rand(rng)
end

#   using Gadfly
#   x = [draw(g) for k in 1:100]
#   Gadfly.plot(sin, 0,1)

###################
# Define the derivative of sumsq
rdiff(sumsq, (zeros(3),))


@deriv_rule sumsq(x)   x   2x

sumsq2(x::Number,y::Number) = x^2 + y^2
sumsq2_rdiff = rdiff(sumsq2, (0.,0.))

#d1_sumsq2(x,y) = sumsq2_rdiff(x,y)[2]
#d2_sumsq2(x,y) = sumsq2_rdiff(x,y)[3]
#@deriv_rule sumsq2(x,y)   x   d1_sumsq2(x,y)
#@deriv_rule sumsq2(x,y)   y   d2_sumsq2(x,y)

rosenbrock(x::Float32,y::Float32) = sumsq2(1 - x, 10*(x - y^2))
rosenbrock_diff = rdiff(rosenbrock, (0.,0.))
rosenbrock_diff(1.,2.)

rosenbrockN_ex = :((1 - x[1])^2 + 100*sumsq(x[2:end] - x[1:end-1].^2))
rdiff(rosenbrockN_ex, x=zeros(4))

mahal_ex= :(mahal(ltri_unpack(x[1:3], x[4:6]), x[7:9], x[10:12]))

@eval mahal_new(x) = $mahal_ex
mahal_new(rand(12))

f=rdiff(mahal, (zeros(3,3),zeros(3),zeros(3),), )
f.
f(rand(3,3), rand(3), rand(3))

# This one not so good: unmanaged type int
lla(alphas::Vec) = log_likelihood_mat(alphas, hcat(g.mus...), hcat(g.LDs...), hcat(g.LTs...), x)
dx = rdiff(lla, alphas=g.alphas)
dx([-1,-248,-240,-1,-2])

Pkg.dir("ReverseDiffSource")
#           Query(

# abstract Visitor

# type myvisitor <: Visitor
#   index::Int64

#   myvisitor() = new(0)
# end

# v = myvisitor()

# function visit(v::myvisitor, obj::Number)
#   ++v.index
#   println(v)
# end

# function visit(v::Visitor, obj::Any)
#   fields = names(obj)
#   if length(fields) == 0
#     println("Cannot handle a [", typeof(obj), "]")
#   else
#     for n in names(obj)
#       visit(v, obj.(n))
#     end
#   end
# end

# visit(v, gmm_test)

# methods(Array)
