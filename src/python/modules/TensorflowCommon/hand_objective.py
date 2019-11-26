import tensorflow as tf
from modules.TensorflowCommon.utils import shape


def to_pose_params(theta, nbones):
    def tail_generator(theta):
        '''Help function for generating pose params.'''

        i_theta = 6
        n_fingers = 5
        zeros = tf.zeros((3, ), dtype = tf.float64)

        # posed params have the following structure:
        #       [ head ]
        #       [ tail ]
        #
        # this function generates tail which form is:
        #       [ *, *, 0 ]
        #       [ *, 0, 0 ]
        #       [ *, 0, 0 ]
        #       [ 0, 0, 0 ]
        #       ... repeats n_fingers times ...
        for _ in range(n_fingers):
            yield tf.concat((                        # [ *, *, 0]
                theta[i_theta: i_theta + 2],
                tf.reshape(zeros[0], (1, )),
            ), 0)
            i_theta += 2

            for _ in range(2):
                yield tf.concat((                    # [ *, 0, 0] 2 times
                    tf.reshape(theta[i_theta], (1, )),
                    zeros[: 2]
                ), 0)

                i_theta += 1

            yield zeros     # [ 0, 0, 0 ]

    head = tf.stack((
        theta[0: 3],
        tf.ones((3, ), dtype = tf.float64),
        theta[3: 6],
        tf.zeros((3, ), dtype = tf.float64),
        tf.zeros((3, ), dtype = tf.float64)
    ))

    tail = tf.stack(tuple(tail_generator(theta)))
    return tf.concat((head, tail), 0)



def euler_angles_to_rotation_matrix(xzy):
    tx = xzy[0]
    ty = xzy[2]
    tz = xzy[1]

    ctx = tf.math.cos(tx)
    stx = tf.math.sin(tx)

    cty = tf.math.cos(ty)
    sty = tf.math.sin(ty)

    ctz = tf.math.cos(tz)
    stz = tf.math.sin(tz)

    Rx = tf.convert_to_tensor([
        [ 1,    0,    0 ],
        [ 0,  ctx, -stx ],
        [ 0,  stx,  ctx ]
    ], dtype = tf.float64)

    Ry = tf.convert_to_tensor([
        [ cty,    0, -sty ],
        [   0,    1,    0 ],
        [ sty,    0,  cty ]
    ], dtype = tf.float64)

    Rz = tf.convert_to_tensor([
        [ ctz, -stz,  0 ],
        [ stz,  ctz,  0 ],
        [   0,    0,  1 ]
    ], dtype = tf.float64)

    return (Rz @ Ry) @ Rx



def get_posed_relatives(pose_params, base_relatives):
    def inner(rot_param, base_relative):
        R = euler_angles_to_rotation_matrix(rot_param)

        # tr has the following form
        #       [ R  0 ]
        #       [ 0  1 ]
        tr = tf.concat((R, tf.zeros((3, 1), dtype = tf.float64)), 1)
        tr = tf.concat((tr, tf.constant([0, 0, 0, 1], shape = (1, 4), dtype = tf.float64)), 0)

        return base_relative @ tr

    relatives = tf.stack([
        inner(pose_params[3:][i], base_relatives[i])
        for i in range(pose_params[3:].shape[0])
    ])

    return relatives



def relatives_to_absolutes(relatives, parents):
    absolutes = []
    for i in range(relatives.shape[0]):
        if parents[i] == -1:
            absolutes.append(relatives[i])
        else:
            absolutes.append(absolutes[parents[i]] @ relatives[i])

    return tf.stack(absolutes)



def angle_axis_to_rotation_matrix(angle_axis):
    n = tf.math.sqrt(tf.reduce_sum(angle_axis ** 2, 0))

    def aa2R():
        angle_axis_normalized = angle_axis / n

        x = angle_axis_normalized[0]
        y = angle_axis_normalized[1]
        z = angle_axis_normalized[2]

        s, c = tf.sin(n), tf.cos(n)
        R = tf.convert_to_tensor([
            [ x*x + (1 - x*x)*c,   x*y*(1 - c) - z*s,   x*z*(1 - c) + y*s ],
            [ x*y*(1 - c) + z*s,   y*y + (1 - y*y)*c,   y*z*(1 - c) - x*s ],
            [ x*z*(1 - c) - y*s,   z*y*(1 - c) + x*s,   z*z + (1 - z*z)*c ]
        ], dtype = tf.float64)

        return R

    if n < 0.0001:
        return tf.eye(3, dtype=tf.float64)
    else:
        return aa2R()



def apply_global_transform(pose_params, positions):
    R = angle_axis_to_rotation_matrix(pose_params[0])
    s = pose_params[1]
    R *= s
    t = pose_params[2]
    return tf.transpose(R @ tf.transpose(positions)) + t



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
    transforms = tf.stack([
        (absolutes[i] @ inverse_base_absolutes[i])
        for i in range(len(absolutes))
    ])

    positions = tf.transpose(
        tf.transpose(
            tf.stack([
                transforms[i, :, :] @ tf.transpose(base_positions)
                for i in range(transforms.shape[0])
            ]),
            perm = [2, 1, 0]
        ),
        perm = [0, 2, 1]
    )

    positions2 = tf.reduce_sum(positions * tf.reshape(weights, (shape(weights) + [1])), 1)[:, :3]
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

    err = tf.stack([
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
    us = tf.reshape(all_params[: 2 * npts], (npts, 2))
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

    err = tf.stack([
        points[i] - get_hand_pt(us[i], triangles[int(correspondences[i])])
        for i in range(points.shape[0])
    ])

    return err