# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import torch

from modules.PyTorchVmap.utils import torch_jacobian


def to_pose_params(theta, nbones):
    pose_params = torch.zeros((int(nbones) + 3, 3),
                              dtype=torch.float64,
                              device=theta.device)

    pose_params[0, :] = theta[0:3]
    pose_params[1, :] = torch.ones((3, ), device=theta.device)
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


def euler_angles_to_rotation_matrix_batched(xzy):
    tx = xzy[:, 0]
    ty = xzy[:, 2]
    tz = xzy[:, 1]

    Rx = torch.eye(3, device=xzy.device).unsqueeze(0).broadcast_to(
        xzy.shape[0], -1, -1).contiguous()
    Rx[:, 1, 1] = torch.cos(tx)
    Rx[:, 2, 1] = torch.sin(tx)
    Rx[:, 1, 2] = -Rx[:, 2, 1]
    Rx[:, 2, 2] = Rx[:, 1, 1]

    Ry = torch.eye(3, device=xzy.device).unsqueeze(0).broadcast_to(
        xzy.shape[0], -1, -1).contiguous()
    Ry[:, 0, 0] = torch.cos(ty)
    Ry[:, 2, 0] = torch.sin(ty)
    Ry[:, 0, 2] = -Ry[:, 2, 0]
    Ry[:, 2, 2] = Ry[:, 0, 0]

    Rz = torch.eye(3, device=xzy.device).unsqueeze(0).broadcast_to(
        xzy.shape[0], -1, -1).contiguous()
    Rz[:, 0, 0] = torch.cos(tz)
    Rz[:, 1, 0] = torch.sin(tz)
    Rz[:, 0, 1] = -Rz[:, 1, 0]
    Rz[:, 1, 1] = Rz[:, 0, 0]

    return torch.bmm(torch.bmm(Rz, Ry), Rx)


def get_posed_relatives(pose_params, base_relatives):
    rot_params = pose_params[3:]
    trs = torch.eye(4, dtype=torch.float64,
                    device=rot_params.device).unsqueeze(0).broadcast_to(
                        rot_params.shape[0], -1, -1).contiguous()
    Rs = euler_angles_to_rotation_matrix_batched(rot_params)
    trs[:, :3, :3] = Rs
    return torch.bmm(base_relatives, trs)


def relatives_to_absolutes(relatives, parents):

    absolutes = []
    for i in range(relatives.shape[0]):
        if parents[i] == -1:
            absolutes.append(relatives[i])
        else:
            absolutes.append(absolutes[parents[i]] @ relatives[i])

    return torch.stack(absolutes)


def angle_axis_to_rotation_matrix(angle_axis):
    n = torch.sqrt(torch.sum(angle_axis**2))

    def aa2R():
        angle_axis_normalized = angle_axis / n
        x = angle_axis_normalized[0]
        y = angle_axis_normalized[1]
        z = angle_axis_normalized[2]
        s, c = torch.sin(n), torch.cos(n)
        R = torch.zeros((3, 3), dtype=torch.float64, device=angle_axis.device)
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
        return torch.eye(3, deivce=angle_axis.device)
    else:
        return aa2R()


def apply_global_transform(pose_params, positions):
    R = angle_axis_to_rotation_matrix(pose_params[0])
    s = pose_params[1]
    R *= s
    t = pose_params[2]
    return torch.transpose(R @ torch.transpose(positions, 0, 1), 0, 1) + t


def get_skinned_vertex_positions(pose_params: torch.Tensor,
                                 base_relatives: torch.Tensor,
                                 parents: torch.Tensor,
                                 inverse_base_absolutes: torch.Tensor,
                                 base_positions: torch.Tensor,
                                 weights: torch.Tensor, mirror_factor):
    relatives = get_posed_relatives(pose_params, base_relatives)
    absolutes = relatives_to_absolutes(relatives, parents)
    transforms = torch.bmm(absolutes, inverse_base_absolutes)
    positions = (
        transforms.view(-1, transforms.shape[2]) @ base_positions.T).view(
            transforms.shape[0], -1,
            base_positions.shape[0]).transpose(0, 2).transpose(1, 2)
    positions2 = torch.sum(positions * weights.reshape(weights.shape + (1, )),
                           1)[:, :3]
    positions3 = apply_global_transform(pose_params, positions2)

    return positions3


def hand_objective(params: torch.Tensor, nbones: torch.Tensor,
                   parents: torch.Tensor, base_relatives: torch.Tensor,
                   inverse_base_absolutes: torch.Tensor,
                   base_positions: torch.Tensor, weights: torch.Tensor,
                   mirror_factor: torch.Tensor, points: torch.Tensor,
                   correspondences: torch.Tensor):
    pose_params = to_pose_params(params, nbones)
    vertex_positions = get_skinned_vertex_positions(pose_params,
                                                    base_relatives, parents,
                                                    inverse_base_absolutes,
                                                    base_positions, weights,
                                                    mirror_factor)

    err = points - torch.index_select(vertex_positions, 0,
                                      correspondences.to(torch.int64))

    return err


def hand_objective_complicated_1(theta, nbones, parents, base_relatives,
                                 inverse_base_absolutes, base_positions,
                                 weights, mirror_factor, correspondences,
                                 triangles):
    pose_params = to_pose_params(theta, nbones)
    vertex_positions = get_skinned_vertex_positions(pose_params,
                                                    base_relatives, parents,
                                                    inverse_base_absolutes,
                                                    base_positions, weights,
                                                    mirror_factor)

    selected_triangles = torch.index_select(triangles, 0,
                                            correspondences.to(
                                                torch.int64)).to(torch.int64)
    pos = torch.index_select(
        vertex_positions, 0,
        selected_triangles.flatten()).reshape(selected_triangles.shape +
                                              vertex_positions.shape[1:])
    return pos


def hand_objective_complicated_2(u, pos, point):
    return point - (u[0] * pos[0] + u[1] * pos[1] +
                    (1. - u[0] - u[1]) * pos[2])


def hand_objective_complicated_2_d(u, pos, point):
    return torch_jacobian(hand_objective_complicated_2, (u, pos), (point, ),
                          False)


hand_objective_complicated_2_batched = \
    torch.vmap(hand_objective_complicated_2)
hand_objective_complicated_2_d_batched = \
    torch.vmap(hand_objective_complicated_2_d)


def hand_objective_complicated(all_params, nbones, parents, base_relatives,
                               inverse_base_absolutes, base_positions, weights,
                               mirror_factor, points, correspondences,
                               triangles):
    npts = points.shape[0]
    us = all_params[:2 * npts].reshape((npts, 2))
    theta = all_params[2 * npts:]

    pos = hand_objective_complicated_1(theta, nbones, parents, base_relatives,
                                       inverse_base_absolutes, base_positions,
                                       weights, mirror_factor, correspondences,
                                       triangles)
    err = hand_objective_complicated_2_batched(us, pos, points)

    return err


def hand_objective_complicated_d(all_params, nbones, parents, base_relatives,
                                 inverse_base_absolutes, base_positions,
                                 weights, mirror_factor, points,
                                 correspondences, triangles):
    npts = points.shape[0]
    us = all_params[:2 * npts].reshape((npts, 2))
    theta = all_params[2 * npts:]

    pos, J_pos_theta = torch_jacobian(
        hand_objective_complicated_1,
        (theta, ),
        (nbones, parents, base_relatives, inverse_base_absolutes,
         base_positions, weights, mirror_factor, correspondences, triangles),
        False,
    )
    err, J_err_us_pos = hand_objective_complicated_2_d_batched(us, pos, points)

    J_err_us = J_err_us_pos[:, :, :2]
    J_err_pos = J_err_us_pos[:, :, 2:]
    J_pos_theta = J_pos_theta.view(J_err_pos.shape[0], J_err_pos.shape[2], -1)
    J_err_theta = torch.bmm(J_err_pos, J_pos_theta)

    J_err_us_theta = torch.concat([J_err_us, J_err_theta], dim=2)

    return err, J_err_us_theta.view(-1, J_err_us_theta.shape[-1])
