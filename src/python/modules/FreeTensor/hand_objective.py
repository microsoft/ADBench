import freetensor as ft


@ft.inline
def to_pose_params(theta, nbones):
    pose_params = ft.zeros((int(nbones) + 3, 3), dtype="float64")

    pose_params[0, :] = theta[0:3]
    pose_params[1, :] = ft.ones((3,), dtype="float64")
    pose_params[2, :] = theta[3:6]

    n_fingers = 5
    for i_finger in range(n_fingers):
        for i in range(3):
            i_pose_params = i_finger * 4 + i + 5
            if i == 0:
                pose_params[i_pose_params, 0] = theta[i_finger * 4 + 6]
                pose_params[i_pose_params, 1] = theta[i_finger * 4 + 7]
            else:
                i_theta = i_finger * 4 + i + 1 + 6
                pose_params[i_pose_params, 0] = theta[i_theta]

    return pose_params


@ft.inline
def eye(n):
    ret = ft.empty((n, n), "float64")
    for i in range(n):
        for j in range(n):
            ret[i, j] = 1 if i == j else 0
    return ret


@ft.inline
def euler_angles_to_rotation_matrix(xzy):
    tx = xzy[0]
    ty = xzy[2]
    tz = xzy[1]

    Rx = eye(3)
    Rx[1, 1] = ft.cos(tx)
    Rx[2, 1] = ft.sin(tx)
    Rx[1, 2] = -Rx[2, 1]
    Rx[2, 2] = Rx[1, 1]

    Ry = eye(3)
    Ry[0, 0] = ft.cos(ty)
    Ry[2, 0] = ft.sin(ty)
    Ry[0, 2] = -Ry[2, 0]
    Ry[2, 2] = Ry[0, 0]

    Rz = eye(3)
    Rz[0, 0] = ft.cos(tz)
    Rz[1, 0] = ft.sin(tz)
    Rz[0, 1] = -Rz[1, 0]
    Rz[1, 1] = Rz[0, 0]

    return (Rz @ Ry) @ Rx


@ft.inline
def get_posed_relatives(pose_params, base_relatives):
    relatives = ft.empty((pose_params[3:].shape(0), 4, 4), "float64")
    for i in range(pose_params[3:].shape(0)):
        tr = eye(4)
        R = euler_angles_to_rotation_matrix(pose_params[3:][i])
        tr[:3, :3] = R
        relatives[i] = base_relatives[i] @ tr
    return relatives


@ft.inline
def relatives_to_absolutes(relatives, parents):
    absolutes = ft.empty((relatives.shape(0), 4, 4), "float64")
    for i in range(relatives.shape(0)):
        if parents[i] == -1:
            absolutes[i] = relatives[i]
        else:
            absolutes[i] = absolutes[parents[i]] @ relatives[i]
    return absolutes


@ft.inline
def angle_axis_to_rotation_matrix(angle_axis):
    n = ft.sqrt(ft.reduce_sum(ft.square(angle_axis), keepdims=False))
    R = ft.empty((3, 3), "float64")
    if n < 0.0001:
        R[...] = eye(3)
    else:
        angle_axis_normalized = angle_axis / n
        x = angle_axis_normalized[0]
        y = angle_axis_normalized[1]
        z = angle_axis_normalized[2]
        s, c = ft.sin(n), ft.cos(n)
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


@ft.inline
def apply_global_transform(pose_params, positions):
    R = angle_axis_to_rotation_matrix(pose_params[0])
    s = pose_params[1]
    R[...] *= s
    t = pose_params[2]
    return ft.transpose(R @ ft.transpose(positions, (1, 0)), (1, 0)) + t


@ft.inline
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

    transforms = ft.empty((absolutes.shape(0), 4, 4), "float64")
    for i in range(absolutes.shape(0)):
        transforms[i] = absolutes[i] @ inverse_base_absolutes[i]

    positions0 = ft.empty((transforms.shape(0), 4, base_positions.shape(0)), "float64")
    for i in range(transforms.shape(0)):
        positions0[i] = transforms[i, :, :] @ ft.transpose(base_positions, (1, 0))

    positions1 = ft.transpose(positions0, (2, 0, 1))

    positions2 = ft.reduce_sum(positions1 * ft.unsqueeze(weights, [-1]), [1], keepdims=False)[:, :3]

    positions3 = apply_global_transform(pose_params, positions2)

    return positions3


@ft.inline
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

    err = ft.empty((points.shape(0), 3), "float64")
    for i in range(points.shape(0)):
        err[i] = points[i] - vertex_positions[correspondences[i]]
    return err


@ft.inline
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
    npts = points.shape(0)
    us = ft.reshape(all_params[: 2 * npts], (npts, 2))
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
            u[0] * vertex_positions[triangle[0]] + \
            u[1] * vertex_positions[triangle[1]] + \
            (1. - u[0] - u[1]) * vertex_positions[triangle[2]]

    err = ft.empty((points.shape(0), 3), "float64")
    for i in range(points.shape(0)):
        err[i] = points[i] - get_hand_pt(us[i], triangles[correspondences[i]])
    return err
