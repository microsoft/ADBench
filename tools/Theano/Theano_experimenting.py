# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

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

def read_gmm_instance(fn):
    fid = open(fn, "r")
    line = fid.readline()
    line = line.split()
    d = int(line[0])
    k = int(line[1])
    n = int(line[2])
    alphas = np.array([float(fid.readline()) for i in range(k)])
    def parse_arr(arr):
        return [float(x) for x in arr]   
    means = np.array([parse_arr(fid.readline().split()) for i in range(k)]) 
    icf = np.array([parse_arr(fid.readline().split()) for i in range(k)]) 
    x = np.array([parse_arr(fid.readline().split()) for i in range(n)]) 
    line = fid.readline().split()
    wishart_gamma = float(line[0])
    wishart_m = int(line[1])
    fid.close()
    return alphas,means,icf,x,wishart_gamma,wishart_m

def write_times(fn,tf,tJ):
    fid = open(fn, "w")
    print("%f %f" % (tf,tJ) , file = fid)
    print("tf tJ" , file = fid)
    fid.close()
    
def write_J(fn,grad):
    fid = open(fn, "w")
    J = np.concatenate((grad[0],grad[1].flatten(),grad[2].flatten()))
    print("%i %i" % (1,J.size) , file = fid)
    line = ""
    for elem in J:
        line = line + ("%f " % elem)
    print(line,file = fid)
    fid.close()

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
    def max2(elem, prev_max):
        #return th.ifelse.ifelse(T.lt(prev_max, elem), elem, prev_max)
        return 0.5*(prev_max + elem + T.abs_(prev_max - elem))
    results, updates = th.scan(fn=max2,
                               outputs_info=x[0],
                               sequences=x[1:])
    return results[-1]

def logsumexp(x):
    mx = max_arr(x)
    #mx = T.max(x) #crashes when computing gradient
    return T.log(T.sum(T.exp(x - mx))) + mx

def log_gamma_distrib(a,p):
    def in_loop(i,prev_res):
        j=i+1
        res = prev_res + T.gammaln(a + 0.5*(1 - j))
        return res
    init_val = 0.25 * p * (p - 1) * np.log(np.pi)
    results, updates = th.scan(fn=in_loop,
                               outputs_info=init_val,
                               sequences=[T.arange(p)])
    return results[-1]

def sqsum(x):
    return T.sum(T.square(x))        

def log_wishart_prior(p,gamma,m,sum_qs,Qdiags,icf):
    def in_loop(i,prev_res):
        frobenius = sqsum(Qdiags[i,:]) + sqsum(icf[i,p:])
        res = prev_res + 0.5*gamma*gamma*frobenius
        return res
    n = p + m + 1
    k = sum_qs.shape[0]
    C = n*p*(T.log(gamma)-0.5*np.log(2.)) - log_gamma_distrib(0.5*n,p)
    results, updates = th.scan(fn=in_loop,
                               outputs_info=T.zeros_like(icf[0,0]),
                               sequences=[T.arange(k)])
    return results[-1] - m*T.sum(sum_qs) - k*C

# all ltri, this is out of constructLs
# only because it did not work with c linker
def constructL(ik,d,ltri):
    def construct_cols(i,ltri_idx):
        j = i + 1
        n_elems = d - j
        col = T.join(0,T.zeros((j,1)),T.reshape(T.transpose(ltri[ik,ltri_idx:(ltri_idx+n_elems)]),(n_elems,1)))
        return (ltri_idx+n_elems,col)
    results,_ = th.scan(fn=construct_cols,
                        sequences=T.arange(d),
                        outputs_info=[T.zeros_like(d),None])

    L = T.transpose(results[-1])
    return L

def constructLs(d,ltri):
    k = ltri.shape[0]
    Ls,_ = th.scan(fn=constructL,
                   sequences=T.arange(k),
                   outputs_info=None,
                   non_sequences=[d,ltri])
    return Ls

def max_arr_(x,means):
    results=[]
    for mean in means:
        results.append(T.sum(mean))
    #def max2(mean,data):
    #    xcentered=mean
    #    return T.sum(xcentered)
    #    #xcentered = data - mean
    #    #return sqsum(xcentered)
    #    #return th.ifelse.ifelse(T.lt(prev_max, elem), elem, prev_max)
    #    #return 0.5*(prev_max + elem + T.abs_(prev_max - elem))
    #results, updates = th.scan(fn=max2,
    #                           outputs_info=None,
    #                           sequences=means,
    #                           non_sequences=x)
    return results

def logsumexp_(x,means):
    mx = max_arr_(x,means)
    return mx

# this is out of gmm_objective
# only because it did not work with c linker
def gmm_objective_inner_loop(x,prev_slse,alphas,means,Qdiags,Ls,sum_qs):
    #def main_term(ik):
    #    return x[0,0]
    #    #xcentered = x[ix,:] - means[ik,:]
    #    #Qxcentered = Qdiags[ik,:]*xcentered + T.dot(Ls[ik],xcentered)
    #    #return sqsum(Qxcentered)
    #    #return sqsum(xcentered)
    #k = alphas.shape[0]
    #sqsum_Qxcentered, updates = th.scan(fn=main_term,
    #                           outputs_info=None,
    #                           sequences=T.arange(k))
    sqsum_Qxcentered = logsumexp_(x,means)
        
    slse = prev_slse + logsumexp(alphas + sum_qs - 0.5*sqsum_Qxcentered)
    return slse

def gmm_objective(alphas,means,icf,x,wishart_gamma,wishart_m):
    d = means.shape[1]
    k = means.shape[0]
    n = x.shape[0]
    sum_qs = T.sum(icf[:,:d],1)
    Qdiags = T.exp(icf[:,:d])
    Ls=[]
    #Ls = constructLs(d,icf[:,d:])
    slse_, updates = th.scan(fn=gmm_objective_inner_loop,
                             sequences=x,
                             outputs_info=T.zeros_like(alphas[0]),
                             non_sequences=[alphas,means,Qdiags,Ls,sum_qs])

    #CONSTANT = -n*d*0.5*np.log(2 * np.pi)
    #out = CONSTANT + slse_[-1] - n*logsumexp(alphas)
    #return out + log_wishart_prior(d,wishart_gamma,wishart_m,sum_qs,Qdiags,icf)
    return slse_[-1] + wishart_gamma + wishart_m + x[0,0] + alphas[0] + means[0,0] + icf[0,0]

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
#compile_mode = 'DebugMode'
#compile_mode = th.compile.mode.Mode(linker='c', optimizer='FAST_RUN')
th.config.linker='c'

#def foo(A):
#    def inner(col):
#        results,_ = th.scan(fn=(lambda elem : elem),sequences=col)
#        return results[-1]
#    results,_ = th.scan(fn=inner,sequences=A)
#    return results[-1]

#A = T.dmatrix('A')
##x_ = np.array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]) # works for 15 elements
#A_ = np.array([[1, 2],[3, 4]]) # works for 15 elements

#out = foo(A)
#f = th.function([A], out, mode=compile_mode)
#out_ = f(A_)
#print(out_)
#grad = T.grad(out, A)
#fgrad = th.function([A], grad, mode=compile_mode)
#J = fgrad(A_) # crashes here
#print(J)

start = t.time()
err_ = gmm_objective(alphas_, means_, icf_, x_, wishart_gamma_, wishart_m_)
f = th.function([alphas_, means_, icf_, x_, wishart_gamma_, wishart_m_], err_, mode=compile_mode)
end = t.time()
tf_compile = (end - start)
print("tf_compile: %f" % tf_compile)

#start = t.time()
#grad = T.grad(err_,[alphas_, means_, icf_])
#fgrad = th.function([alphas_, means_, icf_, x_, wishart_gamma_, wishart_m_], grad, mode=compile_mode)
#end = t.time()
#tJ_compile = (end - start)
#print("tJ_compile: %f" % tJ_compile)



ntasks = (len(sys.argv)-1)//3
for task_id in range(ntasks):
    print("task_id: %i" % task_id)

    argv_idx = task_id*3 + 1
    fn = sys.argv[argv_idx]
    nruns_f = int(sys.argv[argv_idx+1])
    nruns_J = int(sys.argv[argv_idx+2])
    
    alphas,means,icf,x,wishart_gamma,wishart_m = read_gmm_instance(fn + ".txt")

    start = t.time()
    for i in range(nruns_f):
        err = f(alphas,means,icf,x,wishart_gamma,wishart_m)
    end = t.time()
    tf = (end - start)/nruns_f
    print("err: %f" % err)

    start = t.time()
    for i in range(nruns_J):
        J = fgrad(alphas,means,icf,x,wishart_gamma,wishart_m)
    end = t.time()
    tJ = ((end - start)/nruns_J) + tf ###!!!!!!!!! adding this because no function value is returned by fgrad
    
    name = "J_Theano"
    write_J(fn + name + ".txt",J)
    write_times(fn + name + "_times.txt",tf,tJ)


