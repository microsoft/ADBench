import math
import freetensor as ft


@ft.inline
def logsumexp(x):
    mx = ft.reduce_max(x, axes=None, keepdims=False)
    emx = ft.exp(x - mx)
    return ft.ln(ft.reduce_sum(emx, axes=[0])) + mx


@ft.inline
def logsumexpvec(x):
    '''The same as "logsumexp" but calculates result for each row separately.'''

    mx = ft.reduce_max(x, axes=[1], keepdims=False)
    lset = ft.logsumexp(ft.transpose(x) - mx, axis=0, keepdims=False)
    return ft.transpose(lset + mx)


@ft.inline
def gammaln(x):
    assert ft.dtype(x) == "float64"
    return ft.unary_op(lambda item: ft.intrinsic("lgamma(%)", item, ret_type="float64"), x)


@ft.inline
def log_gamma_distrib(a, p):
    return ft.reduce_sum(gammaln(a), axes=[-1], keepdims=False) + (p * (p - 1) * math.log(math.pi) * 0.25)


@ft.inline
def sqsum(x):
    return ft.reduce_sum(ft.square(x), axes=[0], keepdims=False)


@ft.inline
def log_wishart_prior(p, wishart_gamma, wishart_m, sum_qs, Qdiags, icf):
    n = p + wishart_m + 1
    k = icf.shape(0)

    out = ft.reduce_sum(
            0.5 * wishart_gamma * wishart_gamma
            * (ft.reduce_sum(ft.square(Qdiags), axes = [1], keepdims=False)
                + ft.reduce_sum(ft.square(icf[:,p:]), axes = [1], keepdims=False))
            - wishart_m * sum_qs,
            keepdims=False)

    C = n * p * (ft.ln(wishart_gamma / math.sqrt(2)))
    return out - k * (C - log_gamma_distrib(0.5 * ft.cast(n, "float64"), p))


@ft.inline
def constructL(d, icf):
    ret = ft.empty((d, d), "float64")

    for i in range(d):
        Lparamidx = (2 * d - i) * (i + 1) // 2
        nelems = d - i - 1
        ret[:, i] = ft.concat([
            ft.zeros((i + 1,), dtype = 'float64'),
            icf[Lparamidx:(Lparamidx + nelems)]
        ])

    return ret


@ft.inline
def Qtimesx(Qdiag, L, x):

    f = ft.einsum('ijk,mik->mij', L, x)
    return Qdiag * x + f


@ft.transform
def gmm_objective(
        alphas, means, icf, x, wishart_gamma, wishart_m,
        d: ft.JIT[int],
        k: ft.JIT[int],
        n: ft.JIT[int]):
    alphas: ft.Var[(k,), "float64"]
    means: ft.Var[(k, d), "float64"]
    icf: ft.Var[(k, d * (d + 1) // 2), "float64"]
    x: ft.Var[(n, d), "float64"]
    wishart_gamma: ft.Var[(), "float64"]
    wishart_m: ft.Var[(), "int32"]

    Qdiags = ft.exp(icf[:, :d])
    sum_qs = ft.reduce_sum(icf[:, :d], axes=[1], keepdims=False)

    Ls = ft.empty((icf.shape(0), d, d), "float64")
    for i in range(icf.shape(0)):
        Ls[i] = constructL(d, icf[i])

    xcentered = ft.empty((n, means.shape(0), d), "float64")
    for i in range(n):
        xcentered[i] = x[i] - means
    Lxcentered = Qtimesx(Qdiags, Ls, xcentered)
    sqsum_Lxcentered = ft.reduce_sum(ft.square(Lxcentered), axes=[2], keepdims=False)
    inner_term = alphas + sum_qs - 0.5 * sqsum_Lxcentered
    lse = logsumexpvec(inner_term)
    slse = ft.reduce_sum(lse, keepdims=False)

    CONSTANT = -n * d * 0.5 * math.log(2 * math.pi)
    return CONSTANT + slse - n * logsumexp(alphas) \
        + log_wishart_prior(d, wishart_gamma, wishart_m, sum_qs, Qdiags, icf)
