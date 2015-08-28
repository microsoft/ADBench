#Pkg.add("ForwardDiff")
#Pkg.update()
#Pkg.status()
using ForwardDiff

include("common.jl")

function gmm_objective(alphas,means,icf,x)
  d = size(x,1)
  n = size(x,2)
  CONSTANT = -n*d*0.5*log(2 * pi)

  # function to combine log-diagonal an lower triangle
  sum_qs = sum(icf[1:d,:],1)
  slse = sum(sum_qs)
  Qs = [get_Q(d,icf[:,ik]) for ik in 1:k]
  main_term = zeros(eltype(alphas),1,k)

  slse = 0.
  for ix=1:n
    for ik=1:k
      main_term[ik] = -0.5*sum(Qs[ik] * (x[:,ix] - means[:,ik]))
    end
    slse += logsumexp(alphas + sum_qs + main_term)
  end

  CONSTANT + slse - n*logsumexp(alphas)
end

# Generate random instance
d = 2
k = 3
n = 2
icf_sz = div(d*(d + 1),2)
alphas=rand(1,k);
means=randn(d,k)
icf=randn(icf_sz,k)
x = randn(d,n)

# Objective
err = gmm_objective(alphas,means,icf,x)
@printf "err: %f\n" err

# Gradient helper
function wrapper_gmm_objective(packed)
  alphas,means,icf = unpack(d,k,packed)
  gmm_objective(alphas,means,icf,x)
end

# Gradient
g = ForwardDiff.gradient(wrapper_gmm_objective)
J = g(pack(alphas,means,icf))
println("J:")
println(J)

fn = "C:\\Users\\t-filsra\\Workspace\\autodiff\\gmm.txt"

replicate_point = false
alphas,means,icf,x = read_gmm_instance(fn,replicate_point)
