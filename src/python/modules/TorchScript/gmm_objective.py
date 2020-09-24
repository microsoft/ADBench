# TorchScript adapation of https://github.com/microsoft/ADBench/blob/70e2e936bea81eebf0de78ce18d4d196daf1204e/src/python/modules/PyTorch/gmm_objective.py

import math

# from scipy import special as scipy_special
from modules.TorchScript import torch_multigammaln
import torch


@torch.jit.script
def logsumexp(x):
    mx = torch.max(x)
    emx = torch.exp(x - mx)
    # Python builtin <built-in function sum> is currently not supported in Torchscript
    # return torch.log(sum(emx)) + mx
    return torch.log(torch.sum(emx)) + mx


@torch.jit.script
def logsumexpvec(x):
    """The same as "logsumexp" but calculates result for each row separately."""

    mx = torch.max(x, 1).values
    lset = torch.logsumexp(torch.t(x) - mx, 0)
    return torch.t(lset + mx)


@torch.jit.script
def log_gamma_distrib(a:torch.Tensor, p: int):
    # return scipy_special.multigammaln(a, p)
    return torch_multigammaln.multigammaln(a, p)


@torch.jit.script
def sqsum(x):
    # Python builtin <built-in function sum> is currently not supported in Torchscript
    return torch.sum(x ** 2)

# TODO: pass only Qdiag and icf (as is done in the F#) - AWF
@torch.jit.script
def log_wishart_prior(p: int, wishart_gamma, wishart_m, sum_qs, Qdiags, icf):
    n = p + wishart_m + 1
    k = icf.shape[0]

    out = torch.sum(
        0.5
        * wishart_gamma
        * wishart_gamma
        * (torch.sum(Qdiags ** 2, dim=1) + torch.sum(icf[:, p:] ** 2, dim=1))
        - wishart_m * sum_qs
    )

    C = n * p * (math.log(wishart_gamma / math.sqrt(2)))

    return out - k * (C - log_gamma_distrib(0.5 * n, p))


@torch.jit.script
def make_L_col_lifted(d: int, icf, constructL_Lparamidx: int, i: int):
    nelems = d - i - 1
    col = torch.cat(
        [
            torch.zeros(i + 1, dtype=torch.float64),
            icf[constructL_Lparamidx : (constructL_Lparamidx + nelems)],
        ]
    )

    constructL_Lparamidx += nelems
    return (constructL_Lparamidx, col)

@torch.jit.script
def constructL(d: int, icf):
    # constructL.Lparamidx = d
    constructL_Lparamidx = d

    # torch.jit.frontend.UnsupportedNodeError: function definitions aren't supported:

    # def make_L_col(i):
    #     nelems = d - i - 1
    #     col = torch.cat([
    #         torch.zeros(i + 1, dtype = torch.float64),
    #         icf[constructL.Lparamidx:(constructL.Lparamidx + nelems)]
    #     ])

    #     constructL.Lparamidx += nelems
    #     return col

    # columns = [make_L_col(i) for i in range(d)]

    columns = []
    for i in range(0, d):
        constructL_Lparamidx_update, col = make_L_col_lifted(
            d, icf, constructL_Lparamidx, i
        )
        columns.append(col)
        constructL_Lparamidx = constructL_Lparamidx_update

    return torch.stack(columns, -1)


@torch.jit.script
def Qtimesx(Qdiag, L, x):

    f = torch.einsum("ijk,mik->mij", L, x)
    return Qdiag * x + f


@torch.jit.script
def gmm_objective(alphas, means, icf, x, wishart_gamma, wishart_m):
    n = x.shape[0]
    d = x.shape[1]

    Qdiags = torch.exp(icf[:, :d])
    sum_qs = torch.sum(icf[:, :d], 1)
    Ls = torch.stack([constructL(d, curr_icf) for curr_icf in icf])

    # GeneratorExp aren't supported:
    # Tensor cannot be used as a tuple
    #
    # but I believe we don't need to do the tuple()
    xcentered = torch.stack([x[i] - means for i in range(n)])

    Lxcentered = Qtimesx(Qdiags, Ls, xcentered)
    sqsum_Lxcentered = torch.sum(Lxcentered ** 2, 2)
    inner_term = alphas + sum_qs - 0.5 * sqsum_Lxcentered
    lse = logsumexpvec(inner_term)
    slse = torch.sum(lse)

    CONSTANT = -n * d * 0.5 * math.log(2 * math.pi)
    return (
        CONSTANT
        + slse
        - n * logsumexp(alphas)
        + log_wishart_prior(d, wishart_gamma, wishart_m, sum_qs, Qdiags, icf)
    )