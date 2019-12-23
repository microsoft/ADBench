# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#Pkg.add("ReverseDiffSource")
#Pkg.update()
#Pkg.checkout("ReverseDiffSource","devl")
#Pkg.status()
using ReverseDiffSource

typealias Mat Matrix{Float64}

function function2expression(f::Function, sig::Tuple; order::Int=1, evalmod=Main, debug=false, allorders=true)
    fs = methods(f, map( typeof, sig ))
    length(fs) == 0 && error("ardiff: no function '$f' found for signature $sig")
    length(fs) > 1  && error("ardiff: several functions $f found for signature $sig")  # is that possible ?

    fdef  = fs[1].func.code
    fcode = Base.uncompressed_ast(fdef)
    fargs = fcode.args[1]  # function parameters

    cargs = [ (fargs[i], sig[i]) for i in 1:length(sig) ]
    expr = ReverseDiffSource.streamline(fcode.args[3])
    expr,cargs
end

function logsumexp(x::Mat)
  mx = maximum(x)
  log(sum(exp(x .- mx))) + mx
end

gmm_objective_code =
  :(begin
      n = size(x,2)
      d = size(x,1)
      CONSTANT = -n*d*0.5*log(2 * pi)

      sum_qs = similar(alphas)
      for ik in 1:k
        sum_qs[ik] = sum(icf[1:d,ik])
      end

      main_term = similar(alphas)
      slse = 0.
      for ix in 1:n
        for ik in 1:k
          Qxcentered = get_Q(d,icf[:,ik])*(x[:,ix] - means[:,ik])
          main_term[ik] = -0.5*sum(Qxcentered.^2)
        end
        slse += logsumexp(alphas + sum_qs + main_term)
      end
      return CONSTANT + slse - n*logsumexp(alphas)
  end)

k=3
d=2
n=3
icf_sz=div(d*(d + 1),2)
alphas = randn(1,k)
means = randn(d,k)
icf = randn(icf_sz,k)
x = randn(d,n)

logsumexp_code,cargs = function2expression(logsumexp, (alphas,))
logsumexp_d_code = rdiff(logsumexp_code; x=alphas, allorders=false)
@eval logsumexp_d(x) = $logsumexp_d_code
@deriv_rule logsumexp(x) x logsumexp_d(x)
@deriv_rule similar(x) x zeros(size(x))


function make_row(r::Int, diag_elem, L)
      elems=zeros(eltype(L),1,r-1)
      for i=1:r-1
        elems[i]=L[i]
      end
      return [elems diag_elem zeros(d-r)']
end

@deriv_rule make_row(r,diag_elem,L) r 0.
@deriv_rule make_row(r,diag_elem,L) diag_elem make_row(r,0.,ones(L)).*ds
@deriv_rule make_row(r,diag_elem,L) L make_row(r,1.,zeros(L)).*ds
make_row_code_d_code = rdiff(make_row,(1,2,icf[d+1:end,:]))

function ltri_unpack(D,LT)
  d=length(D)
  sum(D)+sum(LT)
  function make_row(r::Int, L)
    elems=zeros(eltype(L),1,r-1)
    for i=1:r-1
      elems[i]=L[i]
    end
    hcat(elems, D[r], zeros(1,d-r))
  end
  #row_start(r::Int) = div((r-1)*(r-2),2)
  #inds(r) = row_start(r)+(1:r-1)
  #vcat([ make_row(r, LT[inds(r)]) for r=1:d ]...)
end
ltri_unpack_code,cargs = function2expression(ltri_unpack, (icf[1:d,1],icf[d+1:end,1]))
ltri_unpack_d_code = rdiff(ltri_unpack_code; D=icf[1:d,1], LT=icf[d+1:end,1])
@eval logsumexp_d(x) = $ltri_unpack_d_code
@deriv_rule ltri_unpack(x) x ltri_unpack_d(x)





#gmm_objective_AD_code,cargs = function2expression(gmm_objective_AD, (alphas,x))
gmm_objective_AD_d_code = rdiff(gmm_objective_code;alphas=alphas,means=means,icf=icf)
@eval g(alphas,means,icf) = $gmm_objective_AD_d_code
g(alphas,means,icf)

include("common.jl")

# input should be 1 dimensional
function logsumexp(x)
  mx = maximum(x)
  log(sum(exp(x - mx))) + mx
end

@inbounds function gmm_objective(alphas,means,icf,x,wishart::Wishart)
  d = size(x,1)
  n = size(x,2)
  CONSTANT = -n*d*0.5*log(2 * pi)

  sum_qs = sum(icf[1:d,:],1)
  slse = sum(sum_qs)
  Qs = [get_Q(d,icf[:,ik]) for ik in 1:k]
  main_term = zeros(eltype(alphas),1,k)

  slse = 0.
  for ix=1:n
    for ik=1:k
      main_term[ik] = -0.5*sumabs2(Qs[ik] * (x[:,ix] - means[:,ik]))
    end
    slse += logsumexp(alphas + sum_qs + main_term)
  end

  CONSTANT + slse - n*logsumexp(alphas) + log_wishart_prior(wishart, sum_qs, Qs, icf)
end

# Read instance
dir_in = ARGS[1]
dir_out = ARGS[2]
fn = ARGS[3]
nruns_f = parse(Int,ARGS[4])
nruns_J = parse(Int,ARGS[5])
replicate_point = size(ARGS,1) >= 6 && ARGS[6] == "-rep"

fn_in = string(dir_in, fn)
fn_out = string(dir_out, fn)

alphas,means,icf,x,wishart = read_gmm_instance(string(fn_in,".txt"),replicate_point)
d = size(means,1)
k = size(means,2)
n = size(x,2)

# Objective
precompile(gmm_objective,(typeof(alphas),typeof(means),typeof(icf),typeof(x),Wishart))
tic()
for i in 1:nruns_f
  err = gmm_objective(alphas,means,icf,x,wishart)
end
tf = toq()/nruns_f;
@printf "tf: %g\n" tf
#@printf "err: %f\n" err

# Gradient helper
function wrapper_gmm_objective(packed)
  alphas,means,icf = unpack(d,k,packed)
  gmm_objective(alphas,means,icf,x,wishart)
end

# Gradient
g = ForwardDiff.gradient(wrapper_gmm_objective)
precompile(pack,(typeof(alphas),typeof(means),typeof(icf)))
precompile(g,(typeof(alphas),typeof(means),typeof(icf)))
J = zeros(1,length(alphas)+length(means)+length(icf))
tic()
for i in 1:nruns_J
  J = g(pack(alphas,means,icf))
end
tJ = toq()/nruns_J;
@printf "tJ: %g\n" tJ
#println("J:")
#println(J)

name = "Julia_F"

write_J(string(fn_out,"_J_",name,".txt"),J)
write_times(string(fn_out,"_times_",name,".txt"),tf,tJ)

