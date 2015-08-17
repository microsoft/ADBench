import numpy as np
from numpy.random import rand, randn
from scipy import special as scipy_special
import theano as th
import theano.tensor as T
import time as t
import sys

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

def logsumexp(x):
    mx = T.max(x,0)
    semx = T.sum(T.exp(x - mx))
    return T.log(semx) + mx

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

def Ltimesx(d,ltri,x):
    def inner_term(i,ltri_idx,prev_res):
        j = i + 1
        n_elems = d - j
        res = T.concatenate((prev_res[:j],prev_res[j:] + ltri[ltri_idx:(ltri_idx+n_elems)]*x[i]))
        return (ltri_idx+n_elems,res)
    results, updates = th.scan(fn=inner_term,
                               outputs_info=(T.zeros_like(d),T.zeros_like(x)),
                               sequences=[T.arange(d)])
    return results[-1][-1]

def gmm_objective(alphas,means,icf,x,wishart_gamma,wishart_m):
    d = means.shape[1]
    k = means.shape[0]
    n = x.shape[0]
    sum_qs = T.sum(icf[:,:d],1)
    Qdiags = T.exp(icf[:,:d])

    def inner_loop(ix,prev_slse,ltri_pack):
        def main_term(ik,dummy,curr_x):
            xcentered = curr_x - means[ik,:]
            Qxcentered = Qdiags[ik,:]*xcentered + Ltimesx(d,ltri_pack[ik,:],xcentered)
            return sqsum(Qxcentered)
        k = alphas.shape[0]
        sqsum_Qxcentered, updates = th.scan(fn=main_term,
                               outputs_info=T.zeros_like(x[0,0]),
                               sequences=[T.arange(k)],
                               non_sequences=[x[ix,:]])

        slse = prev_slse + logsumexp(alphas + sum_qs - 0.5*sqsum_Qxcentered)
        return slse
    slse_, updates = th.scan(fn=inner_loop,
                             outputs_info=T.zeros_like(alphas[0]),
                             sequences=[T.arange(n)],
                             non_sequences=[icf[:,d:]])

    CONSTANT = -n*d*0.5*np.log(2 * np.pi)
    out = CONSTANT + slse_[-1] - n*logsumexp(alphas)
    return out + log_wishart_prior(d,wishart_gamma,wishart_m,sum_qs,Qdiags,icf)

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

err_ = gmm_objective(alphas_, means_, icf_, x_, wishart_gamma_, wishart_m_)
f = th.function([alphas_, means_, icf_, x_, wishart_gamma_, wishart_m_], err_,mode='FAST_RUN')
#grad = T.grad(err_,[alphas_, means_, icf_])
#fgrad = th.function([alphas_, means_, icf_, x_, wishart_gamma_, wishart_m_],grad,mode='FAST_RUN')

ntasks = (len(sys.argv)-1)//2
for task_id in range(ntasks):
    print("task_id: %i" % task_id)

    argv_idx = task_id*2 + 1
    fn = sys.argv[argv_idx]
    nruns = int(sys.argv[argv_idx+1])
    
    alphas,means,icf,x,wishart_gamma,wishart_m = read_gmm_instance(fn + ".txt")

    start = t.time()
    for i in range(nruns):
        err = f(alphas,means,icf,x,wishart_gamma,wishart_m)
    end = t.time()
    tf = (end - start)/nruns
    print("err: %f" % err)

    #start = t.time()
    #for i in range(nruns):
    #    J = fgrad(alphas,means,icf,x,wishart_gamma,wishart_m)
    #end = t.time()
    #tJ = ((end - start)/nruns) + tf ###!!!!!!!!! adding this because no function value is returned by fgrad
    
    #name = "J_Theano"
    #write_J(fn + name + ".txt",J)
    #write_times(fn + name + "_times.txt",tf,tJ)


