import sys
import time as t

from scipy import special as scipy_special
#import numpy as np
import autograd.numpy as np
from autograd import value_and_grad

import gmm_objective as gmm

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

def gmm_objective_wrapper(params,x,wishart_gamma,wishart_m):
    return gmm.gmm_objective(params[0],params[1],params[2],x,wishart_gamma,wishart_m)

alphas,means,icf,x,wishart_gamma,wishart_m = read_gmm_instance(sys.argv[1] + ".txt")

nruns_f = int(sys.argv[2])
nruns_J = int(sys.argv[3])

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
name = "J_Autograd"
if nruns_J>0:
    tJ = (end - start)/nruns_J
    write_J(sys.argv[1] + name + ".txt",grad[1])

write_times(sys.argv[1] + name + "_times.txt",tf,tJ)