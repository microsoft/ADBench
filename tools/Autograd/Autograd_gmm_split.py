import sys
import time as t

from scipy import special as scipy_special
# import numpy as np
import autograd.numpy as np
from autograd import value_and_grad

sys.path.append(sys.path[0] + ("/" if sys.path[0] else None) + "..")
from python_common import utils
from python_common import gmm_io

import gmm_objective as gmm

######################## Objective ##############################


def logsumexp(x):
    # We need to use these element wise functions
    # because standard array level functions
    # did not work with Autograd
    def scalar_subtract_and_exp(a, scalar):
        return np.asarray([np.exp(a[i] - scalar) for i in range(a.size)])

    mx = np.amax(x)
    emx = scalar_subtract_and_exp(x, mx)
    return np.log(emx.sum()) + mx


def log_gamma_distrib(a, p):
    return scipy_special.multigammaln(a, p)


def sqsum(x):
    return (np.square(x)).sum()


def log_wishart_prior(p, wishart_gamma, wishart_m, icf):
    n = p + wishart_m + 1
    k = icf.shape[0]
    out = 0
    for ik in range(k):
        sum_qs = icf[ik, :p].sum()
        frobenius = sqsum(np.exp(icf[ik, :p])) + sqsum(icf[ik, p:])
        out = out + 0.5 * wishart_gamma * wishart_gamma * frobenius - wishart_m * sum_qs
    C = n * p * (np.log(wishart_gamma) - 0.5 * np.log(2)) - log_gamma_distrib(0.5 * n, p)
    return out - k * C


def constructL(d, icf):
    # Autograd does not support indexed assignment to arrays A[0,0] = x
    constructL.Lparamidx = d

    def make_L_col(i):
        nelems = d - i - 1
        col = np.concatenate(
            (np.zeros(i + 1), icf[constructL.Lparamidx:(constructL.Lparamidx + nelems)]))
        constructL.Lparamidx += nelems
        return col
    columns = [make_L_col(i) for i in range(d)]
    return np.column_stack(columns)


def Qtimesx(Qdiag, L, x):
    # We need to use these element wise functions
    # because standard array level functions
    # did not work with Autograd
    def scalar_multiply(a, scalar):
        return np.asarray([(a[i] * scalar) for i in range(a.size)])

    def cwise_multiply(a, b):
        return np.asarray([(a[i] * b[i]) for i in range(a.size)])

    res = cwise_multiply(Qdiag, x)
    for i in range(L.shape[0]):
        res = res + scalar_multiply(L[:, i], x[i])
    return res


def gmm_objective_split_inner(alphas, means, icf, x):
    def inner_term(ik):
        sum_qs = icf[ik, :d].sum()
        xcentered = x - means[ik, :]
        Qdiag = np.exp(icf[ik, :d])
        L = constructL(d, icf[ik, :])
        Lxcentered = Qtimesx(Qdiag, L, xcentered)
        return alphas[ik] + sum_qs - 0.5 * sqsum(Lxcentered)

    d = x.size
    k = alphas.size
    lse = np.asarray([inner_term(ik) for ik in range(k)])
    return logsumexp(lse)


def gmm_objective_split_other(n, d, alphas, wishart_gamma, wishart_m, icf):
    CONSTANT = -n * d * 0.5 * np.log(2 * np.pi)
    return CONSTANT - n * logsumexp(alphas) + log_wishart_prior(d, wishart_gamma, wishart_m, icf)


def gmm_objective_split(alphas, means, icf, x, wishart_gamma, wishart_m):
    slse = 0
    n = x.shape[0]
    d = x.shape[1]
    for ix in range(n):
        slse = slse + \
            gmm_objective_split_inner(ix, alphas, means, icf, x[ix, :])
    return slse + gmm_objective_split_other(n, d, alphas, wishart_gamma, wishart_m, icf)


def gmm_objective_split_inner_wrapper(params, x):
    return gmm_objective_split_inner(params[0], params[1], params[2], x)


def gmm_objective_split_other_wrapper(params, x, wishart_gamma, wishart_m):
    n = x.shape[0]
    d = x.shape[1]
    return gmm_objective_split_other(n, d, params[0], wishart_gamma, wishart_m, params[2])


def gmm_objective_wrapper(params, x, wishart_gamma, wishart_m):
    return gmm_objective(params[0], params[1], params[2], x, wishart_gamma, wishart_m)


def add_grad(g1, g2):
    return (g1[0] + g2[0], [g1[1][0] + g2[1][0], g1[1][1] + g2[1][1], g1[1][2] + g2[1][2]])


dir_in = sys.argv[1]
dir_out = sys.argv[2]
fn = sys.argv[3]
nruns_f = int(sys.argv[4])
nruns_J = int(sys.argv[5])
time_limit = int(sys.argv[6]) if len(sys.argv) >= 7 else float("inf")
replicate_point = (len(sys.argv) >= 8 and sys.argv[7] == "-rep")

fn_in = dir_in + fn
fn_out = dir_out + fn

alphas, means, icf, x, wishart_gamma, wishart_m = gmm_io.read_gmm_instance(
    fn_in + ".txt", replicate_point)


tf = utils.timer(gmm.gmm_objective, (alphas, means, icf, x, wishart_gamma, wishart_m), nruns=nruns_f, limit=time_limit)

name = "Autograd_split"
if nruns_J > 0:
    # k = alphas.size

    grad_gmm_objective_split_inner_wrapper = value_and_grad(gmm_objective_split_inner_wrapper)
    grad_gmm_objective_split_other_wrapper = value_and_grad(gmm_objective_split_other_wrapper)

    def time_wrapper_J(alphas, means, icf, x, wishart_gamma, wishart_m):
        grad = grad_gmm_objective_split_other_wrapper((alphas, means, icf), x, wishart_gamma, wishart_m)
        for ix in range(x.shape[0]):
            grad = add_grad(grad, grad_gmm_objective_split_inner_wrapper((alphas, means, icf), x[ix, :]))
        return grad

    tJ, grad = utils.timer(time_wrapper_J, (alphas, means, icf, x, wishart_gamma, wishart_m), nruns=nruns_J, limit=time_limit, ret_val=True)

    gmm_io.write_J(fn_out + "_J_" + name + ".txt", grad[1])
else:
    tJ = 0

utils.write_times(fn_out + "_times_" + name + ".txt", tf, tJ)
