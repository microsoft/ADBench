# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import torch


def to_pose_params(theta, nbones):
    pose_params = torch.zeros((int(nbones) + 3, 3), dtype=torch.float64)

    pose_params[0, :] = theta[0:3]
    pose_params[1, :] = torch.ones((3,))
    pose_params[2, :] = theta[3:6]

    i_theta = 6
    i_pose_params = 5
    n_fingers = 5
    for i_finger in range(n_fingers):
        for i in [1, 2, 3]:
            pose_params[i_pose_params, 0] = theta[i_theta]
            i_theta += 1
            if i == 1:
                pose_params[i_pose_params, 1] = theta[i_theta]
                i_theta += 1
            i_pose_params += 1
        i_pose_params += 1

    return pose_params


def euler_angles_to_rotation_matrix(xzy):
    tx = xzy[0]
    ty = xzy[2]
    tz = xzy[1]

    Rx = torch.eye(3)
    Rx[1, 1] = torch.cos(tx)
    Rx[2, 1] = torch.sin(tx)
    Rx[1, 2] = -Rx[2, 1]
    Rx[2, 2] = Rx[1, 1]

    Ry = torch.eye(3)
    Ry[0, 0] = torch.cos(ty)
    Ry[2, 0] = torch.sin(ty)
    Ry[0, 2] = -Ry[2, 0]
    Ry[2, 2] = Ry[0, 0]

    Rz = torch.eye(3)
    Rz[0, 0] = torch.cos(tz)
    Rz[1, 0] = torch.sin(tz)
    Rz[0, 1] = -Rz[1, 0]
    Rz[1, 1] = Rz[0, 0]

    return (Rz @ Ry) @ Rx


def get_posed_relatives(pose_params, base_relatives):
    def inner(rot_param, base_relative):
        tr = torch.eye(4, dtype=torch.float64)
        R = euler_angles_to_rotation_matrix(rot_param)
        tr[:3, :3] = R
        return base_relative @ tr

    relatives = torch.stack([
        inner(pose_params[3:][i], base_relatives[i])
        for i in range(len(pose_params[3:]))
    ])

    return relatives


def relatives_to_absolutes(relatives, parents):

    absolutes = []
    for i in range(relatives.shape[0]):
        if parents[i] == -1:
            absolutes.append(relatives[i])
        else:
            absolutes.append(absolutes[parents[i]] @ relatives[i])

    return torch.stack(absolutes)


def angle_axis_to_rotation_matrix(angle_axis):
    n = torch.sqrt(torch.sum(angle_axis ** 2))

    def aa2R():
        angle_axis_normalized = angle_axis / n
        x = angle_axis_normalized[0]
        y = angle_axis_normalized[1]
        z = angle_axis_normalized[2]
        s, c = torch.sin(n), torch.cos(n)
        R = torch.zeros((3, 3), dtype=torch.float64)
        R[0, 0] = x * x + (1 - x * x) * c
        R[0, 1] = x * y * (1 - c) - z * s
        R[0, 2] = x * z * (1 - c) + y * s

        R[1, 0] = x * y * (1 - c) + z * s
        R[1, 1] = y * y + (1 - y * y) * c
        R[1, 2] = y * z * (1 - c) - x * s

        R[2, 0] = x * z * (1 - c) - y * s
        R[2, 1] = z * y * (1 - c) + x * s
        R[2, 2] = z * z + (1 - z * z) * c
        return R

    if n < 0.0001:
        return torch.eye(3)
    else:
        return aa2R()


def apply_global_transform(pose_params, positions):
    R = angle_axis_to_rotation_matrix(pose_params[0])
    s = pose_params[1]
    R *= s
    t = pose_params[2]
    return torch.transpose(R @ torch.transpose(positions, 0, 1), 0, 1) + t


def get_skinned_vertex_positions(
    pose_params,
    base_relatives,
    parents,
    inverse_base_absolutes,
    base_positions,
    weights,
    mirror_factor
):
    relatives = get_posed_relatives(pose_params, base_relatives)

    absolutes = relatives_to_absolutes(relatives, parents)

    transforms = torch.stack([
        (absolutes[i] @ inverse_base_absolutes[i])
        for i in range(len(absolutes))
    ])

    positions = torch.stack([
        transforms[i, :, :] @ base_positions.transpose(0, 1)
        for i in range(transforms.shape[0])
    ]).transpose(0, 2).transpose(1, 2)

    positions2 = torch.sum(positions * weights.reshape(weights.shape + (1,)), 1)[:, :3]

    positions3 = apply_global_transform(pose_params, positions2)

    return positions3


def hand_objective(
    params,
    nbones,
    parents,
    base_relatives,
    inverse_base_absolutes,
    base_positions,
    weights,
    mirror_factor,
    points,
    correspondences
):
    pose_params = to_pose_params(params, nbones)
    vertex_positions = get_skinned_vertex_positions(
        pose_params,
        base_relatives,
        parents,
        inverse_base_absolutes,
        base_positions,
        weights,
        mirror_factor
    )

    err = torch.stack([
        points[i] - vertex_positions[int(correspondences[i])]
        for i in range(points.shape[0])
    ])

    return err


def hand_objective_complicated(
    all_params,
    nbones,
    parents,
    base_relatives,
    inverse_base_absolutes,
    base_positions,
    weights,
    mirror_factor,
    points,
    correspondences,
    triangles
):
    npts = points.shape[0]
    us = all_params[: 2 * npts].reshape((npts, 2))
    theta = all_params[2 * npts:]
    pose_params = to_pose_params(theta, nbones)
    vertex_positions = get_skinned_vertex_positions(
        pose_params,
        base_relatives,
        parents,
        inverse_base_absolutes,
        base_positions,
        weights,
        mirror_factor
    )

    def get_hand_pt(u, triangle):
        return \
            u[0] * vertex_positions[int(triangle[0])] + \
            u[1] * vertex_positions[int(triangle[1])] + \
            (1. - u[0] - u[1]) * vertex_positions[int(triangle[2])]

    err = torch.stack([
        points[i] - get_hand_pt(us[i], triangles[int(correspondences[i])])
        for i in range(points.shape[0])
    ])

    return err