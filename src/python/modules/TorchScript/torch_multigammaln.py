# TorchScript adapation
# https://github.com/scipy/scipy/blob/c1372d8aa90a73d8a52f135529293ff4edb98fc8/scipy/special/spfun_stats.py

import numpy as np

# from scipy.special import gammaln as loggam
import torch
import math


@torch.jit.script
def multigammaln(a, d: int):
    # Python builtin <built-in function array> is currently not supported in Torchscript:
    # https://github.com/pytorch/pytorch/issues/32268

    # a = np.asarray(a)
    # if not np.isscalar(d) or (np.floor(d) != d):
    #     raise ValueError("d should be a positive integer (dimension)")
    # if np.any(a <= 0.5 * (d - 1)):
    #     raise ValueError("condition a (%f) > 0.5 * (d-1) (%f) not met"
    #                      % (a, 0.5 * (d-1)))

    # res = (d * (d-1) * 0.25) * np.log(np.pi)
    # res += np.sum(loggam([(a - (j - 1.)/2) for j in range(1, d+1)]), axis=0)

    # Need to check relative performance

    res = (d * (d - 1) * 0.25) * math.log(math.pi)
    res += torch.sum(
        torch.tensor(
            [math.lgamma(float(a) - ((j - 1.0) / 2)) for j in range(1, d + 1)]
        ),
        dim=0,
    )
    return res
