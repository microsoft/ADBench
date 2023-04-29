import freetensor as ft
from shared.defs import BA_NCAMPARAMS, ROT_IDX, C_IDX, F_IDX, X0_IDX, RAD_IDX


######### BA objective in Python (FreeTensor) #############

@ft.inline
def cross(a, b):
    y = ft.empty((3,), 'float64')
    y[0] = a[1] * b[2] - a[2] * b[1]
    y[1] = -a[0] * b[2] + a[2] * b[0]
    y[2] = a[0] * b[1] - a[1] * b[0]
    return y


@ft.inline
def rodrigues_rotate_point(rot, X):
    sqtheta = ft.reduce_sum(ft.square(rot), keepdims=False)
    ret = ft.empty((3,), "float64")
    if sqtheta != 0.:
        theta = ft.sqrt(sqtheta)
        costheta = ft.cos(theta)
        sintheta = ft.sin(theta)
        theta_inverse = 1. / theta

        w = theta_inverse * rot
        w_cross_X = cross(w, X)
        tmp = ft.reduce_sum(w * X, keepdims=False) * (1. - costheta)

        ret[...] = X * costheta + w_cross_X * sintheta + w * tmp
    else:
        ret[...] = X + cross(rot, X)
    return ret


@ft.inline
def radial_distort(rad_params, proj):
    rsq = ft.reduce_sum(ft.square(proj), keepdims=False)
    L = 1. + rad_params[0] * rsq + rad_params[1] * rsq * rsq
    return proj * L


@ft.inline
def project(cam, X):
    Xcam = rodrigues_rotate_point(
        cam[ROT_IDX: ROT_IDX + 3], X - cam[C_IDX: C_IDX + 3])
    distorted = radial_distort(cam[RAD_IDX: RAD_IDX + 2], Xcam[0:2] / Xcam[2])
    return distorted * cam[F_IDX] + cam[X0_IDX: X0_IDX + 2]


@ft.transform
def compute_reproj_err(cam, X, w, feat):
    cam: ft.Var[(BA_NCAMPARAMS,), "float64"]
    X: ft.Var[(3,), "float64"]
    w: ft.Var[(), "float64"]
    feat: ft.Var[(2,), "float64"]

    return w * (project(cam, X) - feat)

@ft.transform
def compute_w_err(w):
    w: ft.Var[(), "float64"]

    ret = ft.empty((), "float64")
    ret[...] = 1.0 - ft.square(w)
    return ret
