# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import math
from scipy import special
import tensorflow as tf

from modules.TensorflowCommon.utils import shape



def logsumexp(x):
    mx = tf.reduce_max(x)
    return tf.reduce_logsumexp(x - mx) + mx



def logsumexpvec(x):
    '''The same as "logsumexp" but calculates result for each row separately.'''

    mx = tf.reduce_max(x, 1)
    lset = tf.reduce_logsumexp(tf.transpose(x) - mx, 0)
    return tf.transpose(lset + mx)



def log_gamma_distrib(a, p):
    return special.multigammaln(a, p)



def log_wishart_prior(p, wishart_gamma, wishart_m, sum_qs, Qdiags, icf):
    n = p + wishart_m + 1
    k = shape(icf)[0]

    out = tf.reduce_sum(
        0.5 * wishart_gamma * wishart_gamma *
        (tf.reduce_sum(Qdiags ** 2, 1) + tf.reduce_sum(icf[:, p:] ** 2, 1)) -
        wishart_m * sum_qs
    )
    
    C = n * p * (math.log(wishart_gamma / math.sqrt(2)))
    return out - k * (C - log_gamma_distrib(0.5 * n, p))



def constructL(d, icf):
    constructL.Lparamidx = d

    def make_L_col(i):
        nelems = d - i - 1
        col = tf.concat([
            tf.zeros(i + 1, dtype = tf.float64),
            icf[constructL.Lparamidx:(constructL.Lparamidx + nelems)]
        ], 0)

        constructL.Lparamidx += nelems
        return col

    columns = tuple(make_L_col(i) for i in range(d))
    return tf.stack(columns, -1)



def Qtimesx(Qdiag, L, x):
    return Qdiag * x + tf.linalg.matvec(L, x)



def gmm_objective(alphas, means, icf, x, wishart_gamma, wishart_m):
    xshape = shape(x)
    n = xshape[0]
    d = xshape[1]

    Qdiags = tf.exp(icf[:, :d])
    sum_qs = tf.reduce_sum(icf[:, :d], 1)

    icf_sz = shape(icf)[0]
    Ls = tf.stack(tuple( constructL(d, icf[i]) for i in range(icf_sz) ))

    xcentered = tf.stack(tuple( x[i] - means for i in range(n) ))
    Lxcentered = Qtimesx(Qdiags, Ls, xcentered)
    sqsum_Lxcentered = tf.reduce_sum(Lxcentered ** 2, 2)
    inner_term = alphas + sum_qs - 0.5 * sqsum_Lxcentered
    lse = logsumexpvec(inner_term)
    slse = tf.reduce_sum(lse)

    const = tf.constant(
        -n * d * 0.5 * math.log(2 * math.pi),
        dtype = tf.float64
    )

    return const + slse - n * logsumexp(alphas) + \
        log_wishart_prior(d, wishart_gamma, wishart_m, sum_qs, Qdiags, icf)