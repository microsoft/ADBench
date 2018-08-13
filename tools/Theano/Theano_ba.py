import sys
import os
import time as t

import numpy as np

import theano as th
import theano.ifelse
import theano.tensor as T
import theano.compile
import theano.compile.mode

from ..python_common import utils
from ..python_common import ba_io


############## Objective in theano ##################

BA_NCAMPARAMS = 11
ROT_IDX = 0
C_IDX = 3
F_IDX = 6
X0_IDX = 7
RAD_IDX = 9


def cross(a, b):
    return T.as_tensor([
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0]])


def rodrigues_rotate_point(rot, X):
    sqtheta = T.sum(T.sqr(rot))

    def branch1():
        theta = T.sqrt(sqtheta)
        costheta = T.cos(theta)
        sintheta = T.sin(theta)
        theta_inverse = 1. / theta

        w = theta_inverse * rot
        w_cross_X = cross(w, X)
        tmp = T.dot(w, X) * (1. - costheta)

        return X * costheta + w_cross_X * sintheta + w * tmp

    def branch2():
        return X + cross(rot, X)

    return th.ifelse.ifelse(T.neq(sqtheta, 0.), branch1(), branch2())


def radial_distort(rad_params, proj):
    rsq = T.sum(T.sqr(proj))
    L = 1. + rad_params[0] * rsq + rad_params[1] * rsq * rsq
    return proj * L


def project(cam, X):
    Xcam = rodrigues_rotate_point(
        cam[ROT_IDX:ROT_IDX + 3], X - cam[C_IDX:C_IDX + 3])
    distorted = radial_distort(cam[RAD_IDX:RAD_IDX + 2], Xcam[0:2] / Xcam[2])
    return distorted * cam[F_IDX] + cam[X0_IDX:X0_IDX + 2]


def compute_reproj_err(cam, X, w, feat):
    return w * (project(cam, X) - feat)


def ba_objective(cams, X, w, obs, feats):

    def compute_reproj_err_wrapper(curr_w, o, feat):
        return compute_reproj_err(cams[o[0]], X[o[1]], curr_w, feat)
    reproj_err, _ = th.scan(fn=compute_reproj_err_wrapper,
                            outputs_info=None,
                            sequences=[w, obs, feats])

    w_err = 1. - T.sqr(w)

    return (reproj_err, w_err)


def compute_w_err(w):
    return 1. - w * w


cams_ = T.dmatrix('cams_')
X_ = T.dmatrix('X_')
w_ = T.dvector('w_')
obs_ = T.imatrix('obs_')
feats_ = T.dmatrix('feats_')

# compile_mode = 'FAST_COMPILE'
compile_mode = 'FAST_RUN'
th.config.linker = 'cvm'

start = t.time()
reproj_err_, w_err_ = ba_objective(cams_, X_, w_, obs_, feats_)
f = th.function([cams_, X_, w_, obs_, feats_],
                (reproj_err_, w_err_), mode=compile_mode)
end = t.time()
tf_compile = (end - start)
print("tf_compile: %f" % tf_compile)

####### Derivative extras ########

start = t.time()


def compute_ba_J(cams, X, w, obs, feats):

    def compute_reproj_err_d_wrapper(curr_w, o, feat):
        curr_cam = cams[o[0]]
        curr_X = X[o[1]]
        return T.jacobian(compute_reproj_err(curr_cam, curr_X, curr_w, feat),
                          [curr_cam, curr_X, curr_w])
        # return compute_reproj_err_d(cams[o[0]],X[o[1]],curr_w,feat)
    reproj_err_d, _ = th.scan(fn=compute_reproj_err_d_wrapper,
                              outputs_info=None,
                              sequences=[w, obs, feats])

    # w_err_d,_ = th.scan(fn=compute_w_err_d,
    def compute_w_err_d_wrapper(curr_w):
        return T.grad(compute_w_err(curr_w), [curr_w])
    w_err_d, _ = th.scan(fn=compute_w_err_d_wrapper,
                         outputs_info=None,
                         sequences=w)

    return (reproj_err_d[0], reproj_err_d[1], reproj_err_d[2], w_err_d)


cams_d_, X_d_, w_d_, w_err_d_ = compute_ba_J(cams_, X_, w_, obs_, feats_)
f_compute_ba_J = th.function(
    [cams_, X_, w_, obs_, feats_], (cams_d_, X_d_, w_d_, w_err_d_), mode=compile_mode)

end = t.time()
tJ_compile = (end - start)
print("tJ_compile: %f" % tJ_compile)

####### Run experiments ########

ntasks = (len(sys.argv) - 1) // 5
time_limit = int(sys.argv[-1]) if len(sys.argv) >= (ntasks * 5 + 2) else float("inf")
for task_id in range(ntasks):
    print("task_id: %i" % task_id)

    argv_idx = task_id * 5 + 1
    dir_in = sys.argv[argv_idx]
    dir_out = sys.argv[argv_idx + 1]
    fn = sys.argv[argv_idx + 2]
    nruns_f = int(sys.argv[argv_idx + 3])
    nruns_J = int(sys.argv[argv_idx + 4])

    fn_in = dir_in + fn
    fn_out = dir_out + fn

    cams, X, w, obs, feats = ba_io.read_ba_instance(fn_in + ".txt")

    tf, err = utils.timer(f, (cams, X, w, obs, feats), nruns=nruns_f, limit=time_limit, ret_val=True)
    # print("err:")
    # print(err)

    name = "Theano"

    if nruns_J > 0:
        tJ, J = utils.timer(f_compute_ba_J, (cams, X, w, obs, feats), nruns=nruns_J, limit=time_limit, ret_val=True)
        tJ += tf  # !!!!!!!!! adding this because no function value is returned by fJ
        # ba_io.write_J(fn_out + "_J_" + name + ".txt",J)
    else:
        tJ = 0

    utils.write_times(fn_out + "_times_" + name + ".txt", tf, tJ)
