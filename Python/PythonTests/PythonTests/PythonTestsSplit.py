#import numpy as np
import autograd.numpy as np
from scipy import special as scipy_special
from autograd import value_and_grad
import time as t
import sys

######################## IO ##############################

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
    
######################## Objective ##############################

def logsumexp(x):
    # We need to use these element wise functions
    # because standard array level functions 
    # did not work with Autograd
    def scalar_subtract_and_exp(a,scalar):
        return np.asarray([np.exp(a[i] - scalar) for i in range(a.size)])

    mx = np.amax(x)
    emx = scalar_subtract_and_exp(x,mx)
    return np.log(emx.sum()) + mx

def log_gamma_distrib(a,p):
    return scipy_special.multigammaln(a,p)

def sqsum(x):
    return (np.square(x)).sum()

def log_wishart_prior(p,wishart_gamma,wishart_m,icf):
    n = p + wishart_m + 1
    k = icf.shape[0]
    out = 0
    for ik in range(k):
        sumlog_Ldiag = icf[ik,:p].sum()
        frobenius = sqsum(np.exp(icf[ik,:p])) + sqsum(icf[ik,p:])
        out = out + 0.5*wishart_gamma*wishart_gamma*frobenius - wishart_m*sumlog_Ldiag
    C = n*p*(np.log(wishart_gamma)-0.5*np.log(2)) - log_gamma_distrib(0.5*n,p)
    return out - k*C

def constructL(d,icf):
    # Autograd does not support indexed assignment to arrays A[0,0] = x 
    constructL.Lparamidx = d
    def make_L_col(i):
        nelems = d-i-1
        col = np.concatenate((np.zeros(i+1),icf[constructL.Lparamidx:(constructL.Lparamidx+nelems)]))
        constructL.Lparamidx += nelems
        return col
    columns = [make_L_col(i) for i in range(d)]
    return np.column_stack(columns)


def Ltimesx(Ldiag,L,x):
    # We need to use these element wise functions
    # because standard array level functions 
    # did not work with Autograd
    def scalar_multiply(a,scalar):
        return np.asarray([(a[i] * scalar) for i in range(a.size)])
    def cwise_multiply(a,b):
        return np.asarray([(a[i] * b[i]) for i in range(a.size)])

    res = cwise_multiply(Ldiag,x)
    for i in range(L.shape[0]):
        res = res + scalar_multiply(L[:,i],x[i]) 
    return res

def gmm_objective_split_inner(alphas,means,icf,x):
    def inner_term(ik):
        sumlog_Ldiag = icf[ik,:d].sum()
        xcentered = x - means[ik,:]
        Ldiag = np.exp(icf[ik,:d])
        L = constructL(d,icf[ik,:])
        Lxcentered = Ltimesx(Ldiag,L,xcentered)
        sqsum_Lxcentered = sqsum(Lxcentered)
        return alphas[ik] + sumlog_Ldiag - 0.5*sqsum_Lxcentered
    
    d = x.size
    k = alphas.size
    lse = np.asarray([inner_term(ik) for ik in range(k)])
    return logsumexp(lse)

def gmm_objective_split_other(n,d,alphas,wishart_gamma,wishart_m,icf):
    CONSTANT = -n*d*0.5*np.log(2 * np.pi)
    return CONSTANT - n*logsumexp(alphas) + log_wishart_prior(d,wishart_gamma,wishart_m,icf)

def gmm_objective_split(alphas,means,icf,x,wishart_gamma,wishart_m):
    slse = 0
    n = x.shape[0]
    d = x.shape[1]
    for ix in range(n):
        slse = slse + gmm_objective_split_inner(ix,alphas,means,icf,x[ix,:])
    return slse + gmm_objective_split_other(n,d,alphas,wishart_gamma,wishart_m,icf)

def gmm_objective_split_inner_wrapper(params,x):
    return gmm_objective_split_inner(params[0],params[1],params[2],x)

def gmm_objective_split_other_wrapper(params,x,wishart_gamma,wishart_m):
    n = x.shape[0]
    d = x.shape[1]
    return gmm_objective_split_other(n,d,params[0],wishart_gamma,wishart_m,params[2])

def gmm_objective(alphas,means,icf,x,wishart_gamma,wishart_m):
    def inner_term(ix,ik):
        sumlog_Ldiag = icf[ik,:d].sum()
        xcentered = x[ix,:] - means[ik,:]
        Lxcentered = Ltimesx(Ldiags[ik,:],Ls[ik,:,:],xcentered)
        sqsum_Lxcentered = sqsum(Lxcentered)
        return alphas[ik] + sumlog_Ldiag - 0.5*sqsum_Lxcentered

    n = x.shape[0]
    d = x.shape[1]
    k = alphas.size
    Ldiags = np.asarray([(np.exp(icf[ik,:d])) for ik in range(k)])
    Ls = np.asarray([constructL(d,curr_icf) for curr_icf in icf])
    slse = 0
    for ix in range(n):
        lse = np.asarray([inner_term(ix,ik) for ik in range(k)])
        slse = slse + logsumexp(lse)

    CONSTANT = -n*d*0.5*np.log(2 * np.pi)
    return CONSTANT + slse - n*logsumexp(alphas) + log_wishart_prior(d,wishart_gamma,wishart_m,icf)

def gmm_objective_wrapper(params,x,wishart_gamma,wishart_m):
    return gmm_objective(params[0],params[1],params[2],x,wishart_gamma,wishart_m)

def add_grad(g1,g2):
    return (g1[0]+g2[0],[g1[1][0]+g2[1][0],g1[1][1]+g2[1][1],g1[1][2]+g2[1][2]])

alphas,means,icf,x,wishart_gamma,wishart_m = read_gmm_instance(sys.argv[1] + ".txt")

nruns = int(sys.argv[2])

start = t.time()
for i in range(nruns):
    err = gmm_objective(alphas,means,icf,x,wishart_gamma,wishart_m)
end = t.time()
tf = (end - start)/nruns

k = alphas.size
grad_gmm_objective_split_inner_wrapper = value_and_grad(gmm_objective_split_inner_wrapper)
grad_gmm_objective_split_other_wrapper = value_and_grad(gmm_objective_split_other_wrapper)
start = t.time()
for i in range(nruns):
    grad = grad_gmm_objective_split_other_wrapper((alphas,means,icf),x,wishart_gamma,wishart_m)
    for ix in range(x.shape[0]):
        grad = add_grad(grad,grad_gmm_objective_split_inner_wrapper((alphas,means,icf),x[ix,:]))
end = t.time()
tJ = (end - start)/nruns

name = "J_Autograd_split"
write_J(sys.argv[1] + name + ".txt",grad[1])
write_times(sys.argv[1] + name + "_times.txt",tf,tJ)