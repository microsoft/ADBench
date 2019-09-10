import sys
from os import path

# adding folder with files for importing
sys.path.append(
    path.join(
        path.abspath(path.dirname(__file__)),
        "..",
        "..",
        "shared"
    )
)

import torch
from defs import BA_NCAMPARAMS, ROT_IDX, C_IDX, F_IDX, X0_IDX, RAD_IDX


######### BA objective in Python (torch) #############

def rodrigues_rotate_point(rot, X):
    sqtheta = torch.sum(rot ** 2)
    if sqtheta != 0.:
        theta = torch.sqrt(sqtheta)
        costheta = torch.cos(theta)
        sintheta = torch.sin(theta)
        theta_inverse = 1. / theta

        w = theta_inverse * rot
        w_cross_X = torch.cross(w, X)
        tmp = torch.dot(w, X) * (1. - costheta)

        return X * costheta + w_cross_X * sintheta + w * tmp
    else:
        return X + torch.cross(rot, X)


def radial_distort(rad_params, proj):
    rsq = torch.sum(proj ** 2)
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
    reproj_err = torch.empty((p, 2), dtype=torch.float64)
    for i in range(p):
        reproj_err[i] = compute_reproj_err(
            cams[obs[i, 0]], X[obs[i, 1]], w[i], feats[i])

    w_err = 1. - w ** 2

    return torch.cat((reproj_err.flatten(), w_err))
