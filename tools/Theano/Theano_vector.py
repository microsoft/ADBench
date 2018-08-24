import sys
import os
import time as t

import numpy as np
from numpy.random import rand, randn
from scipy import special as scipy_special

import theano as th
import theano.tensor as T
import theano.ifelse
import theano.compile
import theano.compile.mode

sys.path.append(sys.path[0] + ("/" if sys.path[0] else None) + "..")
from python_common import utils
from python_common import gmm_io


############## Objective in theano ##################

def mkmat(name,rows,cols):
    tmp = T.dmatrix(name)
    tmp.tag.test_value = rand(rows,cols)
    return tmp

def mkvec(name,sz):
    tmp = T.dvector(name)
    tmp.tag.test_value = rand(sz)
    return tmp

def mkscalar(name):
    tmp = T.dscalar(name)
    tmp.tag.test_value = 47.
    return tmp

def max_arr(x):
    def max2(elems, prev_max):
        #return th.ifelse.ifelse(T.lt(prev_max, elem), elem, prev_max)
        return 0.5*(prev_max + elems + T.abs_(prev_max - elems))
    results, updates = th.scan(fn=max2,
                               outputs_info=x[0],
                               sequences=x[1:])
    return results[-1]

def logsumexp(x):
    mx = max_arr(x)
    #mx = T.max(x,axis=0) #this crashes (sometimes)
    return T.log(T.sum(T.exp(x - mx),axis=0)) + mx

def log_gamma_distrib(a,p):
    def in_loop(i,prev_res):
        j=i+1
        res = prev_res + T.gammaln(a + 0.5*(1 - j))
        return res
    init_val = 0.25 * p * (p - 1) * np.log(np.pi)
    results,_ = th.scan(fn=in_loop,
                               outputs_info=init_val,
                               sequences=[T.arange(p)])
    return results[-1]

def sqnorm(x,axis=0):
    return T.sum(T.square(x),axis=axis)

def log_wishart_prior(p,gamma,m,sum_qs,Qdiags,icf):
    def in_loop(Qdiag,icf,prev_res):
        frobenius = sqnorm(Qdiag) + sqnorm(icf[p:])
        res = prev_res + 0.5*gamma*gamma*frobenius
        return res
    n = p + m + 1
    k = sum_qs.shape[0]
    C = n*p*(T.log(gamma)-0.5*np.log(2.)) - log_gamma_distrib(0.5*n,p)
    results,_ = th.scan(fn=in_loop,
                               outputs_info=T.zeros_like(icf[0,0]),
                               sequences=[Qdiags,icf])
    return results[-1] - m*T.sum(sum_qs) - k*C

def constructLs(d,ltri):
    def constructL(ltri):
        tmp = T.transpose(T.tril(T.ones((d,d)),-1))
        lower_tril_indices = tmp.nonzero()
        L = T.transpose(T.set_subtensor(tmp[lower_tril_indices], ltri))
        return L

    Ls,_ = th.scan(fn=constructL,
                   sequences=ltri,
                   outputs_info=None)
    return Ls

def gmm_objective(alphas,means,icf,x,wishart_gamma,wishart_m):
    d = means.shape[1]
    k = means.shape[0]
    n = x.shape[0]
    sum_qs = T.sum(icf[:,:d],1)
    Qdiags = T.exp(icf[:,:d])
    Ls = constructLs(d,icf[:,d:])

    def inner_term(alpha,mean,Qdiag,L,sum_qs,x):
        xcentered = x - mean
        Qxcentered = xcentered*Qdiag + T.dot(xcentered,T.transpose(L))
        return alpha + sum_qs - 0.5*sqnorm(Qxcentered,axis=1)
    main_term,_ = th.scan(fn=inner_term,
                             sequences=[alphas,means,Qdiags,Ls,sum_qs],
                             outputs_info=None,
                             non_sequences=x)
    slse = T.sum(logsumexp(main_term))

    CONSTANT = -n*d*0.5*np.log(2 * np.pi)
    out = CONSTANT + slse - n*logsumexp(alphas)
    return out + log_wishart_prior(d,wishart_gamma,wishart_m,sum_qs,Qdiags,icf)

#th.config.compute_test_value = 'warn'
d_ = 3;
k_ = 5;
n_ = 10;
icf_sz_ = d_*(d_ + 1) / 2;
alphas_ = mkvec('alphas',k_)
means_ = mkmat('means',k_,d_)
icf_ = mkmat('icf',k_,icf_sz_)
x_ = mkmat('x',n_,d_)
wishart_gamma_ = mkscalar('wishart_gamma')
wishart_m_ = mkscalar('wishart_m') 

#compile_mode = 'FAST_COMPILE'
compile_mode = 'FAST_RUN'
th.config.linker='cvm'

start = t.time()
err_ = gmm_objective(alphas_, means_, icf_, x_, wishart_gamma_, wishart_m_)
f = th.function([alphas_, means_, icf_, x_, wishart_gamma_, wishart_m_], err_, mode=compile_mode)
end = t.time()
tf_compile = (end - start)
print("tf_compile: %f" % tf_compile)

start = t.time()
grad = T.grad(err_,[alphas_, means_, icf_])
fgrad = th.function([alphas_, means_, icf_, x_, wishart_gamma_, wishart_m_], grad, mode=compile_mode)
end = t.time()
tJ_compile = (end - start)
print("tJ_compile: %f" % tJ_compile)

ntasks = (len(sys.argv)-1)//5
replicate_point = (len(sys.argv) >= (ntasks*5+2) and sys.argv[-1] == "-rep")

for task_id in range(ntasks):
    print("task_id: %i" % task_id)

    argv_idx = task_id*5 + 1
    dir_in = sys.argv[argv_idx]
    dir_out = sys.argv[argv_idx+1]
    fn = sys.argv[argv_idx+2]
    nruns_f = int(sys.argv[argv_idx+3])
    nruns_J = int(sys.argv[argv_idx+4])

    fn_in = dir_in + fn;
    fn_out = dir_out + fn;
    
    alphas,means,icf,x,wishart_gamma,wishart_m = gmm_io.read_gmm_instance(fn_in + ".txt", replicate_point)

    start = t.time()
    for i in range(nruns_f):
        err = f(alphas,means,icf,x,wishart_gamma,wishart_m)
    end = t.time()
    tf = (end - start)/nruns_f
    print("err:")
    print(err)
    
    name = "Theano_vector"

    tJ = 0
    if nruns_J > 0:
        start = t.time()
        for i in range(nruns_J):
            J = fgrad(alphas,means,icf,x,wishart_gamma,wishart_m)
        end = t.time()
        tJ = ((end - start)/nruns_J) + tf ###!!!!!!!!! adding this because no function value is returned by fgrad
        gmm_io.write_J(fn_out + "_J_" + name + ".txt",J)    
    
    utils.write_times(fn_out + "_times_" + name + ".txt",tf,tJ)
