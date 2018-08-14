import sys
import time as t

# import numpy as np
import autograd.numpy as np
from autograd import value_and_grad
from autograd import jacobian
from autograd import elementwise_grad
from autograd.core import primitive

sys.path.append(sys.path[0] + ("/" if sys.path[0] else None) + "..")
from python_common import utils
from python_common import ba_io

# implementing derivative of cross


@primitive
def cross(a, b):
    out = np.empty(3)
    out[0] = a[1] * b[2] - a[2] * b[1]
    out[1] = a[2] * b[0] - a[0] * b[2]
    out[2] = a[0] * b[1] - a[1] * b[0]
    return out


def make_grad_cross_0(ans, a, b):
    def gradient_product(g):
        return cross(g, -b)
    return gradient_product


def make_grad_cross_1(ans, a, b):
    def gradient_product(g):
        return cross(g, a)
    return gradient_product


cross.defgrad(make_grad_cross_0, argnum=0)
cross.defgrad(make_grad_cross_1, argnum=1)

######### BA objective in Python #############

BA_NCAMPARAMS = 11
ROT_IDX = 0
C_IDX = 3
F_IDX = 6
X0_IDX = 7
RAD_IDX = 9


def rodrigues_rotate_point(rot, X):
    sqtheta = np.sum(np.square(rot))
    if sqtheta != 0.:
        theta = np.sqrt(sqtheta)
        costheta = np.cos(theta)
        sintheta = np.sin(theta)
        theta_inverse = 1. / theta

        w = theta_inverse * rot
        w_cross_X = cross(w, X)
        tmp = np.dot(w, X) * (1. - costheta)

        return X * costheta + w_cross_X * sintheta + w * tmp
    else:
        return X + cross(rot, X)


def radial_distort(rad_params, proj):
    rsq = np.sum(np.square(proj))
    L = 1. + rad_params[0] * rsq + rad_params[1] * rsq * rsq
    return proj * L


def project(cam, X):
    Xcam = rodrigues_rotate_point(
        cam[ROT_IDX: ROT_IDX + 3], X - cam[C_IDX: C_IDX + 3])
    distorted = radial_distort(cam[RAD_IDX: RAD_IDX + 2], Xcam[0:2] / Xcam[2])
    return distorted * cam[F_IDX] + cam[X0_IDX: X0_IDX + 2]


def compute_reproj_err(cam, X, w, feat):
    return w * (project(cam, X) - feat)


def ba_objective(cams, X, w, obs, feats):
    p = obs.shape[0]
    reproj_err = np.empty((p, 2))
    for i in range(p):
        reproj_err[i] = compute_reproj_err(
            cams[obs[i, 0]], X[obs[i, 1]], w[i], feats[i])

    w_err = 1. - np.square(w)

    return (reproj_err, w_err)

########## derivative extras #############


def compute_w_err(w):
    return 1. - w * w


compute_w_err_d = value_and_grad(compute_w_err)


def compute_reproj_err_wrapper(params, feat):
    X_off = BA_NCAMPARAMS
    return compute_reproj_err(params[0:X_off], params[X_off: X_off + 3], params[-1], feat)


compute_reproj_err_d = jacobian(compute_reproj_err_wrapper)


def compute_ba_J(cams, X, w, obs, feats):
    p = obs.shape[0]
    reproj_err_d = []
    for i in range(p):
        params = np.hstack((cams[obs[i, 0]], X[obs[i, 1]], w[i]))
        reproj_err_d.append(compute_reproj_err_d(params, feats[i]))

    w_err_d = []
    for curr_w in w:
        w_err_d.append(compute_w_err_d(curr_w))

    return (reproj_err_d, w_err_d)


dir_in = sys.argv[1]
dir_out = sys.argv[2]
fn = sys.argv[3]
nruns_f = int(sys.argv[4])
nruns_J = int(sys.argv[5])
time_limit = int(sys.argv[6]) if len(sys.argv) >= 7 else float("inf")

fn_in = dir_in + fn
fn_out = dir_out + fn

cams, X, w, obs, feats = ba_io.read_ba_instance(fn_in + ".txt")

tf = utils.timer(ba_objective, (cams, X, w, obs, feats),
                 nruns=nruns_f, limit=time_limit)

name = "Autograd"
if nruns_J > 0:
    tJ = utils.timer(compute_ba_J, (cams, X, w, obs, feats),
                     nruns=nruns_J, limit=time_limit)
    # gmm.write_J(fn_out + "_J_" + name + ".txt",grad[1])
else:
    tJ = 0

utils.write_times(fn_out + "_times_" + name + ".txt", tf, tJ)
