import math
from scipy import special
import tensorflow as tf

from modules.TensorflowCommon.utils import shape



def logsumexp(x):
    mx = tf.reduce_max(x)
    return tf.reduce_logsumexp(x - mx) + mx



def log_gamma_distrib(a, p):
    return special.multigammaln(a, p)



def sqsum(x):
    return tf.reduce_sum(x ** 2)



def log_wishart_prior(p, wishart_gamma, wishart_m, sum_qs, Qdiags, icf):
    n = p + wishart_m + 1
    k = shape(icf)[0]

    log2 = tf.math.log(tf.constant(2.0, dtype = tf.float64))
    
    out = tf.reduce_sum([
        0.5 * wishart_gamma * wishart_gamma *
            (sqsum(Qdiags[ik, :]) + sqsum(icf[ik, p:])) -
            wishart_m * sum_qs[ik]

        for ik in range(k)
    ])
    
    C = n * p * (tf.math.log(wishart_gamma) - 0.5 * log2) - \
        log_gamma_distrib(0.5 * n, p)

    return out - k * C



def constructL(d, icf):
    constructL.Lparamidx = d

    def make_L_col(i):
        nelems = d - i - 1
        col = tf.concat([
            tf.zeros(i + 1, dtype=tf.float64),
            icf[constructL.Lparamidx:(constructL.Lparamidx + nelems)]
        ], 0)

        constructL.Lparamidx += nelems
        return col

    columns = [ make_L_col(i) for i in range(d) ]
    return tf.stack(columns, -1)



def Qtimesx(Qdiag, L, x):
    return Qdiag * x + tf.linalg.matvec(L, x)



def gmm_objective(alphas, means, icf, x, wishart_gamma, wishart_m):
    def inner_term(ix, ik):
        xcentered = x[ix, :] - means[ik, :]
        Lxcentered = Qtimesx(Qdiags[ik, :], Ls[ik, :, :], xcentered)
        sqsum_Lxcentered = sqsum(Lxcentered)
        return alphas[ik] + sum_qs[ik] - 0.5 * sqsum_Lxcentered

    n = shape(x)[0]
    d = shape(x)[1]
    k = shape(alphas)[0]

    Qdiags = tf.stack([ (tf.exp(icf[ik, :d])) for ik in range(k) ])
    sum_qs = tf.stack([ (tf.reduce_sum(icf[ik, :d])) for ik in range(k) ])

    Ls = tf.stack([ constructL(d, curr_icf) for curr_icf in icf ])
    slse = tf.reduce_sum([
        logsumexp(lse)
        for lse in [
            tf.stack([ inner_term(ix, ik) for ik in range(k) ])
            for ix in range(n)
        ]
    ])

    const = tf.constant(
        -n * d * 0.5 * math.log(2 * math.pi),
        dtype = tf.float64
    )

    return const + slse - n * logsumexp(alphas) + \
        log_wishart_prior(d, wishart_gamma, wishart_m, sum_qs, Qdiags, icf)