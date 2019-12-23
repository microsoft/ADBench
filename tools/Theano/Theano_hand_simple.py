# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import sys
import os
import time as t

import numpy as np

import theano as th
import theano.tensor as T
import theano.ifelse
import theano.compile
import theano.compile.mode

sys.path.append(sys.path[0] + ("/" if sys.path[0] else None) + "..")
from python_common import utils
from python_common import hand_io

############## Objective in theano ##################


def to_pose_params(theta, nbones):
    pose_params = T.zeros((nbones + 3, 3), theta.dtype)

    pose_params = T.set_subtensor(pose_params[0, :], theta[0:3])
    pose_params = T.set_subtensor(pose_params[1, :], T.ones((3,), theta.dtype))
    pose_params = T.set_subtensor(pose_params[2, :], theta[3:6])

    i_theta = 6
    i_pose_params = 5
    n_fingers = 5
    for i_finger in range(n_fingers):
        for i in [1, 2, 3]:
            pose_params = T.set_subtensor(
                pose_params[i_pose_params, 0], theta[i_theta])
            i_theta += 1
            if i == 1:
                pose_params = T.set_subtensor(
                    pose_params[i_pose_params, 1], theta[i_theta])
                i_theta += 1
            i_pose_params += 1
        i_pose_params += 1

    return pose_params


def euler_angles_to_rotation_matrix(xzy):
    tx = xzy[0]
    ty = xzy[2]
    tz = xzy[1]

    Rx = T.eye(3, dtype=tx.dtype)
    Rx = T.set_subtensor(Rx[1, 1], T.cos(tx))
    Rx = T.set_subtensor(Rx[2, 1], T.sin(tx))
    Rx = T.set_subtensor(Rx[1, 2], -Rx[2, 1])
    Rx = T.set_subtensor(Rx[2, 2], Rx[1, 1])

    Ry = T.eye(3, dtype=tx.dtype)
    Ry = T.set_subtensor(Ry[0, 0], T.cos(ty))
    Ry = T.set_subtensor(Ry[0, 2], T.sin(ty))
    Ry = T.set_subtensor(Ry[2, 0], -Ry[0, 2])
    Ry = T.set_subtensor(Ry[2, 2], Ry[0, 0])

    Rz = T.eye(3, dtype=tx.dtype)
    Rz = T.set_subtensor(Rz[0, 0], T.cos(tz))
    Rz = T.set_subtensor(Rz[1, 0], T.sin(tz))
    Rz = T.set_subtensor(Rz[0, 1], -Rz[1, 0])
    Rz = T.set_subtensor(Rz[1, 1], Rz[0, 0])

    return T.dot(T.dot(Rz, Ry), Rx)


def get_posed_relatives(pose_params, base_relatives):
    def inner(rot_param, base_relative):
        tr = T.eye(4, dtype=base_relative.dtype)
        R = euler_angles_to_rotation_matrix(rot_param)
        tr = T.set_subtensor(tr[:3, :3], R)
        return T.dot(base_relative, tr)

    relatives, _ = th.scan(fn=inner,
                           outputs_info=None,
                           sequences=[pose_params[3:], base_relatives])

    return relatives

### warning, this function contains hack ###


def relatives_to_absolutes(relatives, parents):
    def compute_absolute(i, parent, relative, absolutes):
        # hack (parent == -1 accesses last element - we set it to zero)
        # Theano did not take ifselse here
        absolutes = T.set_subtensor(
            absolutes[i], T.dot(absolutes[parent], relative))
        return absolutes

    absolutes = T.zeros_like(relatives)
    # hack (parent == -1 accesses last element - we set it to zero)
    # Theano did not take ifselse here
    absolutes = T.set_subtensor(absolutes[-1], T.eye(4, dtype=relatives.dtype))
    absolutes_timeline, _ = th.scan(fn=compute_absolute,
                                    sequences=[
                                        T.arange(relatives.shape[0]), parents, relatives],
                                    outputs_info=absolutes)

    return absolutes_timeline[-1]


def angle_axis_to_rotation_matrix(angle_axis):
    n = T.sqrt(T.sum(angle_axis**2))

    def aa2R():
        angle_axis_normalized = angle_axis / n
        x = angle_axis_normalized[0]
        y = angle_axis_normalized[1]
        z = angle_axis_normalized[2]
        s, c = T.sin(n), T.cos(n)
        R = T.zeros((3, 3), dtype=angle_axis.dtype)
        R = T.set_subtensor(R[0, 0], x * x + (1 - x * x) * c)
        R = T.set_subtensor(R[0, 1], x * y * (1 - c) - z * s)
        R = T.set_subtensor(R[0, 2], x * z * (1 - c) + y * s)

        R = T.set_subtensor(R[1, 0], x * y * (1 - c) + z * s)
        R = T.set_subtensor(R[1, 1], y * y + (1 - y * y) * c)
        R = T.set_subtensor(R[1, 2], y * z * (1 - c) - x * s)

        R = T.set_subtensor(R[2, 0], x * z * (1 - c) - y * s)
        R = T.set_subtensor(R[2, 1], z * y * (1 - c) + x * s)
        R = T.set_subtensor(R[2, 2], z * z + (1 - z * z) * c)
        return R

    return th.ifelse.ifelse(T.lt(n, .0001), T.eye(3, dtype=angle_axis.dtype), aa2R())


def apply_global_transform(pose_params, positions):
    R = angle_axis_to_rotation_matrix(pose_params[0])
    s = pose_params[1]
    R *= s[np.newaxis, :]
    t = pose_params[2]
    return T.transpose(T.dot(R, T.transpose(positions))) + t


def get_skinned_vertex_positions(pose_params, base_relatives, parents, inverse_base_absolutes,
                                 base_positions, weights, mirror_factor):
    relatives = get_posed_relatives(pose_params, base_relatives)

    absolutes = relatives_to_absolutes(relatives, parents)

    transforms, _ = th.scan(fn=(lambda A, B: T.dot(A, B)),
                            sequences=[absolutes, inverse_base_absolutes])

    positions = T.tensordot(transforms, base_positions, [
                            2, 1]).dimshuffle((2, 0, 1))

    positions = (positions * weights[:, :, np.newaxis]).sum(axis=1)[:, :3]

    positions = T.set_subtensor(positions[:, 0], positions[:, 0] * mirror_factor)

    positions = apply_global_transform(pose_params, positions)

    return positions


def hand_objective(params, nbones, base_relatives, parents, inverse_base_absolutes, base_positions,
                   weights, mirror_factor, points, correspondences):
    pose_params = to_pose_params(params, nbones)
    vertex_positions = get_skinned_vertex_positions(pose_params, base_relatives, parents,
                                                    inverse_base_absolutes, base_positions,
                                                    weights, mirror_factor)

    err, _ = th.scan(fn=(lambda pt, i_vert: pt - vertex_positions[i_vert]),
                     sequences=[points, correspondences],
                     outputs_info=None)

    return err


params_ = T.dvector('params_')
parents_ = T.ivector('parents_')
base_relatives_ = T.dtensor3('base_relatives_')
inverse_base_absolutes_ = T.dtensor3('inverse_base_absolutes_')
triangles_ = T.imatrix('triangles_')
base_positions_ = T.dmatrix('base_positions_')
weights_ = T.dmatrix('weights_')
nbones_ = T.iscalar('nbones_')
mirror_factor_ = T.dscalar('mirror_factor_')
correspondences_ = T.ivector('correspondences_')
points_ = T.dmatrix('points_')

compile_mode = 'FAST_COMPILE'
# compile_mode = 'FAST_RUN'
th.config.linker = 'cvm'

start = t.time()
err_ = hand_objective(params_, nbones_, base_relatives_, parents_, inverse_base_absolutes_, base_positions_,
                      weights_, mirror_factor_, points_, correspondences_)
f = th.function([params_, nbones_, base_relatives_, parents_, inverse_base_absolutes_, base_positions_,
                 weights_, mirror_factor_, points_, correspondences_], err_, mode=compile_mode)
end = t.time()
tf_compile = (end - start)
print("tf_compile: %f" % tf_compile)

start = t.time()
jac = T.jacobian(T.flatten(err_), [params_])
fjac = th.function([params_, nbones_, base_relatives_, parents_, inverse_base_absolutes_, base_positions_,
                    weights_, mirror_factor_, points_, correspondences_], jac, mode=compile_mode)
end = t.time()
tJ_compile = (end - start)
print("tJ_compile: %f" % tJ_compile)

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

    model_dir = dir_in + "model/"
    fn_in = dir_in + fn
    fn_out = dir_out + fn

    params, data = hand_io.read_hand_instance(model_dir, fn_in + ".txt", False)
    if data.model.is_mirrored:
        mirror_factor = -1.
    else:
        mirror_factor = 1.

    tf, err = utils.timer(f, (
        params, data.model.nbones, data.model.base_relatives, data.model.parents,
        data.model.inverse_base_absolutes, data.model.base_positions,
        data.model.weights, mirror_factor, data.points,
        data.correspondences
    ), nruns=nruns_f, limit=time_limit, ret_val=True)
    print("err:")
    # print(err)

    name = "Theano"

    if nruns_J > 0:
        tJ, J = utils.timer(fjac, (
            params, data.model.nbones, data.model.base_relatives, data.model.parents,
            data.model.inverse_base_absolutes, data.model.base_positions,
            data.model.weights, mirror_factor, data.points,
            data.correspondences
        ), nruns=nruns_J, limit=time_limit, ret_val=True)
        tJ += tf  # !!!!!!!!! adding this because no function value is returned by fjac
        print("J:")
        # print(J)
        hand_io.write_J(fn_out + "_J_" + name + ".txt", J[0])
    else:
        tJ = 0

    utils.write_times(fn_out + "_times_" + name + ".txt", tf, tJ)
