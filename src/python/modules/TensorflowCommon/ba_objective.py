# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import tensorflow as tf
from shared.defs import BA_NCAMPARAMS, ROT_IDX, C_IDX, F_IDX, X0_IDX, RAD_IDX



def rodrigues_rotate_point(rot, X):
    def rotate():
        theta = tf.math.sqrt(sqtheta)
        costheta = tf.math.cos(theta)
        sintheta = tf.math.sin(theta)
        
        w = rot / theta
        w_cross_X = tf.linalg.cross(w, X)
        tmp = tf.tensordot(w, X, 1) * (1.0 - costheta)

        return X * costheta + w_cross_X * sintheta + w * tmp

    sqtheta = tf.reduce_sum(rot ** 2)
    return tf.cond(
        tf.not_equal(sqtheta, 0.0),
        rotate,
        lambda: X + tf.linalg.cross(rot, X)
    )



def radial_distort(rad_params, proj):
    rsq = tf.reduce_sum(proj ** 2)
    L = 1.0 + rad_params[0] * rsq + rad_params[1] * rsq * rsq
    return proj * L



def project(cam, X):
    Xcam = rodrigues_rotate_point(
        cam[ROT_IDX: ROT_IDX + 3],
        X - cam[C_IDX: C_IDX + 3]
    )

    distorted = radial_distort(cam[RAD_IDX: RAD_IDX + 2], Xcam[0:2] / Xcam[2])
    return distorted * cam[F_IDX] + cam[X0_IDX: X0_IDX + 2]



def compute_reproj_err(cam, X, w, feat):
    return w * (project(cam, X) - feat)



def compute_w_err(w):
    return 1.0 - w ** 2