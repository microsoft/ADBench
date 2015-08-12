import numpy as np
from scipy import special as scipy_special
import theano as th
import theano.tensor as T

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

def logsumexp(x):
    mx = np.amax(x)
    semx = (np.exp(x - mx)).sum()
    return np.log(semx) + mx

def log_gamma_distrib(a,p):
    return scipy_special.multigammaln(a,p)
    #out = 0.25 * p * (p - 1) * np.log(np.pi);
    #for j in range(1,p+1):
    #    out = out + scipy_special.gammaln(a + 0.5*(1 - j))
    #return out

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

def Ltimesx(d,icf,x):
    Ldiag = np.exp(icf[:d])
    res = np.multiply(Ldiag,x)
    Lparamidx = d
    for i in range(d):
        for j in range(i+1,d):
            res[j] = res[j] + icf[Lparamidx] * x[i]
            Lparamidx += 1
    return res

def gmm_objective(alphas,means,icf,x,wishart_gamma,wishart_m):
    n = x.shape[0]
    d = x.shape[1]
    k = alphas.size
    slse = 0
    for ix in range(n):
        lse = np.empty(k)
        for ik in range(k):
            sumlog_Ldiag = icf[ik,:d].sum()
            xcentered = x[ix,:] - means[ik,:]
            # Autograd does not support indexed assignment to arrays A[0,0] = x 
            # Hence we do implicit Ltimesx instead of creating a matrix first
            Lxcentered = Ltimesx(d,icf[ik,:],xcentered)
            sqsum_Lxcentered = sqsum(Lxcentered)
            lse[ik] = alphas[ik] + sumlog_Ldiag - 0.5*sqsum_Lxcentered
        slse = slse + logsumexp(lse)

    CONSTANT = -n*d*0.5*np.log(2 * np.pi)
    return CONSTANT + slse - n*logsumexp(alphas) + log_wishart_prior(d,wishart_gamma,wishart_m,icf)

alphas,means,icf,x,wishart_gamma,wishart_m = read_gmm_instance("..\..\..\gmm.txt")

err = gmm_objective(alphas,means,icf,x,wishart_gamma,wishart_m)
print(err)
