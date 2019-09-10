import math
from scipy import special as scipy_special
import torch


def logsumexp(x):
    mx = torch.max(x)
    emx = torch.exp(x - mx)
    return torch.log(sum(emx)) + mx


def log_gamma_distrib(a, p):
    return scipy_special.multigammaln(a, p)


def sqsum(x):
    return sum(x ** 2)


def log_wishart_prior(p, wishart_gamma, wishart_m, sum_qs, Qdiags, icf):
    n = p + wishart_m + 1
    k = icf.shape[0]
    out = 0
    for ik in range(k):
        frobenius = sqsum(Qdiags[ik, :]) + sqsum(icf[ik, p:])
        out = out + 0.5 * wishart_gamma * wishart_gamma * \
            frobenius - wishart_m * sum_qs[ik]
    C = n * p * (math.log(wishart_gamma) - 0.5 * math.log(2)) - log_gamma_distrib(0.5 * n, p)
    return out - k * C


def constructL(d, icf):
    constructL.Lparamidx = d

    def make_L_col(i):
        nelems = d - i - 1
        col = torch.cat([torch.zeros(i + 1, dtype=torch.float64), icf[constructL.Lparamidx:(constructL.Lparamidx + nelems)]])
        constructL.Lparamidx += nelems
        return col
    columns = [make_L_col(i) for i in range(d)]
    return torch.stack(columns, -1)


def Qtimesx(Qdiag, L, x):
    res = Qdiag * x
    for i in range(L.shape[0]):
        res = res + L[:, i] * x[i]
    return res


def gmm_objective(alphas, means, icf, x, wishart_gamma, wishart_m):
    def inner_term(ix, ik):
        xcentered = x[ix, :] - means[ik, :]
        Lxcentered = Qtimesx(Qdiags[ik, :], Ls[ik, :, :], xcentered)
        sqsum_Lxcentered = sqsum(Lxcentered)
        return alphas[ik] + sum_qs[ik] - 0.5 * sqsum_Lxcentered

    n = x.shape[0]
    d = x.shape[1]
    k = alphas.size()[0]

    Qdiags = torch.stack([(torch.exp(icf[ik, :d])) for ik in range(k)])
    sum_qs = torch.stack([(torch.sum(icf[ik, :d])) for ik in range(k)])
    Ls = torch.stack([constructL(d, curr_icf) for curr_icf in icf])
    slse = 0
    for ix in range(n):
        lse = torch.stack([inner_term(ix, ik) for ik in range(k)])
        slse = slse + logsumexp(lse)

    CONSTANT = -n * d * 0.5 * math.log(2 * math.pi)
    return CONSTANT + slse - n * logsumexp(alphas) \
        + log_wishart_prior(d, wishart_gamma, wishart_m, sum_qs, Qdiags, icf)
