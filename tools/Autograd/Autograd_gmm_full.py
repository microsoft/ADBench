import sys
import time as t

from scipy import special as scipy_special
#import numpy as np
import autograd.numpy as np
from autograd import value_and_grad

import gmm_objective as gmm

dir_in = sys.argv[1]
dir_out = sys.argv[2]
fn = sys.argv[3]
nruns_f = int(sys.argv[4])
nruns_J = int(sys.argv[5])
replicate_point = (len(sys.argv) >= 7 and sys.argv[6] == "-rep")

fn_in = dir_in + fn
fn_out = dir_out + fn

def gmm_objective_wrapper(params,x,wishart_gamma,wishart_m):
    return gmm.gmm_objective(params[0],params[1],params[2],x,wishart_gamma,wishart_m)

alphas,means,icf,x,wishart_gamma,wishart_m = gmm.read_gmm_instance(fn_in + ".txt", replicate_point)


start = t.time()
for i in range(nruns_f):
    err = gmm.gmm_objective(alphas,means,icf,x,wishart_gamma,wishart_m)
end = t.time()
tf = (end - start)/nruns_f

k = alphas.size
grad_gmm_objective_wrapper = value_and_grad(gmm_objective_wrapper)
start = t.time()
for i in range(nruns_J):
    grad = grad_gmm_objective_wrapper((alphas,means,icf),x,wishart_gamma,wishart_m)
end = t.time()

tJ = 0
name = "Autograd"
if nruns_J>0:
    tJ = (end - start)/nruns_J
    gmm.write_J(fn_out + "_J_" + name + ".txt",grad[1])

gmm.write_times(fn_out + "_times_" + name + ".txt",tf,tJ)