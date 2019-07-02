/*
 * Manual differentiation of the hand tracking problem.
 * Adapted from the Eigen-based version.
 *
 * Functions in this file do not perform any checks on input parameters
 * for the sake of better performance.
*/

#include "hand_d.h";

#include "../../shared/matrix.h";

// Inputs:
// angle_axis - double[3]
// Outputs:
// R - preallocated 3x3 matrix
// dR - array of 3 preallocated 3x3 matrices
void angle_axis_to_rotation_matrix_d(
    const double const* angle_axis,
    LightMatrix<double>& R,
    std::array<LightMatrix<double>, 3>& dR)
{
    double _sqnorm = sqnorm(3, angle_axis);
    double norm = sqrt(_sqnorm);
    if (norm < .0001)
    {
        R.set_identity();
        for (int i = 0; i < 3; i++)
            dR[i].fill(0.);
        return;
    }
    double inv_norm = 1. / norm;
    double inv_sqnorm = 1. / _sqnorm;
    double d_norm[3];
    scale(3, inv_norm, angle_axis, d_norm);

    double x = angle_axis[0] * inv_norm;
    double y = angle_axis[1] * inv_norm;
    double z = angle_axis[2] * inv_norm;
    double dx[3], dy[3], dz[3];
    for (int i = 0; i < 3; i++)
    {
        dx[i] = -angle_axis[0] * d_norm[i] * inv_sqnorm;
        dy[i] = -angle_axis[1] * d_norm[i] * inv_sqnorm;
        dz[i] = -angle_axis[2] * d_norm[i] * inv_sqnorm;
    }
    dx[0] += inv_norm;
    dy[1] += inv_norm;
    dz[2] += inv_norm;

    double s = sin(norm);
    double c = cos(norm);
    double dc[3], ds[3];
    scale(3, c, d_norm, ds);
    scale(3, -s, d_norm, dc);

    double r_val[9] = 
    {
        x * x + (1 - x * x) * c, x * y * (1 - c) + z * s, x * z * (1 - c) - y * s,
        x * y * (1 - c) - z * s, y * y + (1 - y * y) * c, z * y * (1 - c) + x * s,
        x * z * (1 - c) + y * s, y * z * (1 - c) - x * s, z * z + (1 - z * z) * c
    }; // col-major
    R.set(r_val);

    for (int i = 0; i < 3; i++)
    {
        double tmp[9] = 
        {
            2 * x * dx[i] - 2 * x * dx[i] * c + (1 - x * x) * dc[i],
            dx[i] * y * (1 - c) + x * dy[i] * (1 - c) - x * y * dc[i] + dz[i] * s + z * ds[i],
            dx[i] * z * (1 - c) + x * dz[i] * (1 - c) - x * z * dc[i] - dy[i] * s - y * ds[i],
            dx[i] * y * (1 - c) + x * dy[i] * (1 - c) - x * y * dc[i] - dz[i] * s - z * ds[i],
            2 * y * dy[i] - 2 * y * dy[i] * c + (1 - y * y) * dc[i],
            dz[i] * y * (1 - c) + z * dy[i] * (1 - c) - z * y * dc[i] + dx[i] * s + x * ds[i],
            dx[i] * z * (1 - c) + x * dz[i] * (1 - c) - x * z * dc[i] + dy[i] * s + y * ds[i],
            dy[i] * z * (1 - c) + y * dz[i] * (1 - c) - y * z * dc[i] - dx[i] * s - x * ds[i],
            2 * z * dz[i] - 2 * z * dz[i] * c + (1 - z * z) * dc[i]
        }; // col-major
        dR[i].set(tmp);
    }
}

// Inputs:
// pose_params - 3xN matrix
// Outputs:
// R - preallocated 3x3 matrix
// dR - array of 3 preallocated 3x3 matrices
void apply_global_transform_d_common(
    const LightMatrix<double>& pose_params, LightMatrix<double>& R, std::array<LightMatrix<double>, 3>& dR)
{
    const double const* global_rotation = pose_params.get_col(0);
    angle_axis_to_rotation_matrix_d(global_rotation, R, dR);

    // const Vector3d& global_rotation = pose_params.col(0);
    // angle_axis_to_rotation_matrix_d(global_rotation, &R, &dR);
    // coef-wise multiplying each row of R by pose_params.get_col(1)
    const double const* pose_params_col1 = pose_params.get_col(1);
    R.scale_col(0, pose_params_col1[0]);
    R.scale_col(1, pose_params_col1[1]);
    R.scale_col(2, pose_params_col1[2]);

    // same for all dR    
    for (int i = 0; i < 3; ++i)
    {
        dR[i].scale_col(0, pose_params_col1[0]);
        dR[i].scale_col(1, pose_params_col1[1]);
        dR[i].scale_col(2, pose_params_col1[2]);
    }
}

// Inputs:
// npts - int
// R - 3x3 matrix
// pose_params - 3xN matrix
// References
// positions - 3xN matrix,
// Outputs:
// pJ - pointer to memory allocated for the jacobian
void apply_global_translation_d(const size_t& npts, const LightMatrix<double>& R, const LightMatrix<double>& pose_params, LightMatrix<double>& positions, double* pJ)
{
    // global translation
    LightMatrix<double> tmp;
    LightMatrix<double> J_glob_translation(3 * npts, 3, &pJ[3 * 3 * npts], false);
    double minusIbuf[9] = { -1., 0., 0., 0., -1., 0., 0., 0., -1. };
    LightMatrix<double> minusI(3, 3, minusIbuf, false);
    for (size_t i = 0; i < npts; ++i)
    {
        J_glob_translation.set_block(i * 3, 0, minusI);
    }

    mat_mult(R, positions, &tmp);
    const double const* pose_params_col2 = pose_params.get_col(2);
    for (int i = 0; i < positions.cols(); ++i)
    {
        double* col = tmp.get_col_ptr(i);
        add_to(3, col, pose_params_col2);
        positions.set_col(i, col);
    }
}

// Inputs:
// corresp - vector<int>
// pose_params - 3xN matrix
// References
// positions - 3xN matrix,
// Outputs:
// pJ - pointer to memory allocated for the jacobian
// R - preallocated 3x3 matrix
void apply_global_transform_d(
    const std::vector<int>& corresp,
    const LightMatrix<double>& pose_params,
    LightMatrix<double>& positions,
    double* pJ,
    LightMatrix<double>& R)
{
    std::array<LightMatrix<double>, 3> dR = { LightMatrix<double>(3, 3), LightMatrix<double>(3, 3) , LightMatrix<double>(3, 3) };
    apply_global_transform_d_common(pose_params, R, dR);

    // global rotation
    size_t npts = corresp.size();
    LightMatrix<double> tmp;
    for (int i_param = 0; i_param < 3; ++i_param)
    {
        LightMatrix<double> J_glob_rot(3, npts, &pJ[i_param * 3 * npts], false);
        for (size_t i_pt = 0; i_pt < npts; i_pt++)
        {
            mat_mult(dR[i_param], LightMatrix<double>(3, 1, positions.get_col_ptr(corresp[i_pt]), false), &tmp);
            J_glob_rot.set_col(i_pt, tmp.get_col(0));
            J_glob_rot.scale_col(i_pt, -1.);
        }
    }

    apply_global_translation_d(npts, R, pose_params, positions, pJ);
}

// Inputs:
// us - double[2 * corresp.size()]
// triangles - vector<Triangle>,
// corresp - vector<int>
// pose_params - 3xN matrix
// References
// positions - 3xN matrix,
// Outputs:
// pJ - pointer to memory allocated for the jacobian
// R - preallocated 3x3 matrix
void apply_global_transform_d(
    const double* const us,
    const std::vector<Triangle>& triangles,
    const std::vector<int>& corresp,
    const LightMatrix<double>& pose_params,
    LightMatrix<double>& positions,
    double* pJ,
    LightMatrix<double>& R)
{
    std::array<LightMatrix<double>, 3> dR = { LightMatrix<double>(3, 3), LightMatrix<double>(3, 3) , LightMatrix<double>(3, 3) };
    apply_global_transform_d_common(pose_params, R, dR);

    // global rotation
    size_t npts = corresp.size();
    double tmp1[3], tmp2[3];
    LightMatrix<double> tmp1_wrapper(3, 1, tmp1, false), tmp_matrix;
    for (int i_param = 0; i_param < 3; ++i_param)
    {
        LightMatrix<double> J_glob_rot(3, npts, &pJ[i_param * 3 * npts], false);
        for (size_t i_pt = 0; i_pt < npts; ++i_pt)
        {
            // tmp1 = u[0] * positions.get_col(verts[0]) + u[1] * positions.get_col(verts[1]) + (1. - u[0] - u[1]) * positions.get_col(verts[2]
            const auto& verts = triangles[corresp[i_pt]].verts;
            const double* const u = &us[2 * i_pt];
            scale(3, u[0], positions.get_col(verts[0]), tmp1);
            scale(3, u[1], positions.get_col(verts[1]), tmp2);
            add_to(3, tmp1, tmp2);
            scale(3, 1. - u[0] - u[1], positions.get_col(verts[2]), tmp2);
            add_to(3, tmp1, tmp2);

            //J_glob_rot.col(i_pt) = -dR[i_param] * tmp1;
            mat_mult(dR[i_param], tmp1_wrapper, &tmp_matrix);
            tmp_matrix.scale_col(0, -1.);
            J_glob_rot.set_block(0, i_pt, tmp_matrix);
        }
    }

    apply_global_translation_d(npts, R, pose_params, positions, pJ);
}

// Inputs:
// relatives - vector of parents.size() 4x4 matrices
// relatives_d  - vector of 4x4 matrices
// parents - vector<int>
// Outputs:
// absolutes - vector of 4x4 matrices, allocated in this function
// absolutes_d - vector of vectors of 4x4 matrices, allocated in this function
void relatives_to_absolutes_d(
    const std::vector<LightMatrix<double>>& relatives,
    const std::vector<LightMatrix<double>>& relatives_d,
    const std::vector<int>& parents,
    std::vector<LightMatrix<double>>& absolutes,
    std::vector<std::vector<LightMatrix<double>>>& absolutes_d)
{
    absolutes.resize(parents.size());
    absolutes_d.resize(parents.size());
    int rel_d_tail = 0;
    for (size_t i = 0; i < parents.size(); ++i)
    {
        if (parents[i] == -1)
            absolutes[i] = relatives[i];
        else
        {
            // absolutes[i] = absolutes[parents[i]] * relatives[i];
            if (parents[i] != i)
                mat_mult(absolutes[parents[i]], relatives[i], &absolutes[i]);
            else
            {
                LightMatrix<double> tmp;
                mat_mult(absolutes[parents[i]], relatives[i], &tmp);
                absolutes[i] = std::move(tmp);
            }
        }

        int n_finger_bone = (i - 1) % 4;
        if (i > 0 && i < parents.size() - 1 && n_finger_bone > 0)
        {
            absolutes_d[i].resize(n_finger_bone + 1);
            int curr_tail = 0;
            int parent = parents[i];

            // absolutes_d[i][curr_tail++] = absolute_d_parent * relatives[i];
            if (parent != i)
            {
                for (const auto& absolute_d_parent : absolutes_d[parent])
                    mat_mult(absolute_d_parent, relatives[i], &absolutes_d[i][curr_tail++]);
            }
            else
            {
                for (int j = 0; j < absolutes_d[parent].size(); ++j)
                {
                    LightMatrix<double> tmp;
                    mat_mult(absolutes_d[parent][j], relatives[i], &tmp);
                    absolutes_d[i][curr_tail++] = std::move(tmp);
                }
            }

            mat_mult(absolutes[parent], relatives_d[rel_d_tail++], &absolutes_d[i][curr_tail++]);
            if (n_finger_bone == 1)
                mat_mult(absolutes[parent], relatives_d[rel_d_tail++], &absolutes_d[i][curr_tail++]);
        }
    }
}

// Inputs:
// xzy - double[3]
// Outputs:
// R - 3x3 matrix, allocated in this function
// pdR0 - nullable pointer to 3x3 matrix (computed only if not null)
// pdR1 - nullable pointer to 3x3 matrix (computed only if not null)
void euler_angles_to_rotation_matrix(
    const double const* xzy,
    LightMatrix<double>& R,
    LightMatrix<double>* pdR0,
    LightMatrix<double>* pdR1)
{
    double tx = xzy[0], ty = xzy[2], tz = xzy[1];
    LightMatrix<double> Rx(3, 3), Ry(3, 3), Rz(3, 3), RzRy(3, 3);
    Rx.set_identity();
    Ry.set_identity();
    Rz.set_identity();
    Rx(1, 1) = cos(tx);
    Rx(2, 1) = sin(tx);
    Rx(1, 2) = -Rx(2, 1);
    Rx(2, 2) = Rx(1, 1);

    Ry(0, 0) = cos(ty);
    Ry(0, 2) = sin(ty);
    Ry(2, 0) = -Ry(0, 2);
    Ry(2, 2) = Ry(0, 0);

    Rz(0, 0) = cos(tz);
    Rz(1, 0) = sin(tz);
    Rz(0, 1) = -Rz(1, 0);
    Rz(1, 1) = Rz(0, 0);

    mat_mult(Rz, Ry, &RzRy);
    mat_mult(RzRy, Rx, &R);

    if (pdR0)
    {
        double zero[9] = { 0., 0., 0., 0., 0., 0., 0., 0., 0. };
        LightMatrix<double> dRx(3, 3, zero, false);
        dRx(1, 1) = -Rx(2, 1);
        dRx(2, 1) = Rx(1, 1);
        dRx(1, 2) = -dRx(2, 1);
        dRx(2, 2) = dRx(1, 1);
        mat_mult(RzRy, dRx, pdR0);
    }
    if (pdR1)
    {
        double zero[9] = { 0., 0., 0., 0., 0., 0., 0., 0., 0. };
        LightMatrix<double> dRz(3, 3, zero, false), RyRx(3, 3);
        dRz(0, 0) = -Rz(1, 0);
        dRz(1, 0) = Rz(0, 0);
        dRz(0, 1) = -dRz(1, 0);
        dRz(1, 1) = dRz(0, 0);
        mat_mult(Ry, Rx, &RyRx);
        mat_mult(dRz, RyRx, pdR1);
    }
}

// Inputs:
// model - HandModelEigen
// pose_params - 3xN matrix
// relatives - vector of 4x4 matrices, allocated in this function
// relatives_d - vector of 4x4 matrices, allocated in this function
void get_posed_relatives_d(
    const HandModelLightMatrix& model,
    const LightMatrix<double>& pose_params,
    std::vector<LightMatrix<double>>& relatives,
    std::vector<LightMatrix<double>>& relatives_d)
{
    relatives.resize(model.base_relatives.size());
    relatives_d.resize(4 * 5); // 4 parameters in every finger

    int offset = 3;
    int tail = 0;
    for (size_t i = 0; i < model.bone_names.size(); ++i)
    {
        LightMatrix<double> tr(4, 4), R(3, 3);
        tr.set_identity();

        int n_finger_bone = (i - 1) % 4;
        if (i == 0 || i == model.bone_names.size() - 1 || n_finger_bone == 0)
        {
            euler_angles_to_rotation_matrix(pose_params.get_col(i + offset), R);
        }
        else
        {
            LightMatrix<double> dtr0(4, 4), dR0(3, 3);
            dtr0.fill(0.);
            if (n_finger_bone == 1)
            {
                LightMatrix<double> dtr1(4, 4), dR1(3, 3);
                dtr1.fill(0.);
                euler_angles_to_rotation_matrix(pose_params.get_col(i + offset), R, &dR0, &dR1);
                dtr1.set_block(0, 0, dR1);
                mat_mult(model.base_relatives[i], dtr1, &relatives_d[tail + 1]);
            }
            else
                euler_angles_to_rotation_matrix(pose_params.get_col(i + offset), R, &dR0);

            dtr0.set_block(0, 0, dR0);
            mat_mult(model.base_relatives[i], dtr0, &relatives_d[tail++]);
            if (n_finger_bone == 1)
                tail++;
        }
        tr.set_block(0, 0, R);

        mat_mult(model.base_relatives[i], tr, &relatives[i]);
    }
}

// Inputs:
// model - HandModelEigen
// pose_params 3xN matrix
// corresp - vector<int>
// Outputs:
// positions - 3xN matrix, allocated in this function
// positions_d - vector of 3xN matrices, allocated in this function
// pJ - pointer to memory allocated for the jacobian
void get_skinned_vertex_positions_d_common(
    const HandModelLightMatrix& model,
    const LightMatrix<double>& pose_params,
    const std::vector<int>& corresp,
    LightMatrix<double>& positions,
    std::vector<LightMatrix<double>>& positions_d,
    double* pJ)
{
    std::vector<LightMatrix<double>> relatives, absolutes, transforms; // vector<Matrix4d>
    std::vector<LightMatrix<double>> relatives_d; // vector<Matrix4d>
    std::vector<std::vector<LightMatrix<double>>> absolutes_d, transforms_d; // vector<vector<Matrix4d>>
    get_posed_relatives_d(model, pose_params, relatives, relatives_d);
    relatives_to_absolutes_d(relatives, relatives_d, model.parents, absolutes, absolutes_d);

    // Get bone transforms.
    transforms.resize(absolutes.size());
    transforms_d.resize(absolutes.size());
    for (size_t i = 0; i < absolutes.size(); ++i)
    {
        mat_mult(absolutes[i], model.inverse_base_absolutes[i], &transforms[i]);
        transforms_d[i].resize(absolutes_d[i].size());
        for (size_t j = 0; j < absolutes_d[i].size(); j++)
            mat_mult(absolutes_d[i][j], model.inverse_base_absolutes[i], &transforms_d[i][j]);
    }

    // Transform vertices by necessary transforms. + apply skinning
    positions = LightMatrix<double>(3, model.base_positions.cols());
    positions.fill(0.);
    positions_d.resize(4 * 5, positions);
    LightMatrix<double> base_positions_homogenized(4, model.base_positions.cols()), tmp;
    base_positions_homogenized.set_block(0, 0, model.base_positions);
    base_positions_homogenized.set_row(3, 1.);
    for (int i = 0; i < (int)transforms.size(); ++i)
    {
        //*positions +=
        //    ((transforms[i] * model.base_positions.colwise().homogeneous()).array()
        //        .rowwise() * model.weights.row(i)).matrix()
        //    .topRows(3);
        mat_mult(transforms[i], base_positions_homogenized, &tmp);
        for (int l = 0; l < 3; ++l)
        {
            for (int k = 0; k < tmp.cols(); ++k)
                positions(l, k) += tmp(l, k) * model.weights(i, k);
        }

        int i_finger = (i - 1) / 4;
        for (int j = 0; j < (int)transforms_d[i].size(); j++)
        {
            int i_param = j + 4 * i_finger;
            mat_mult(transforms_d[i][j], base_positions_homogenized, &tmp);

            //(*positions_d)[i_param] +=
            //    ((transforms_d[i][j] * model.base_positions.colwise().homogeneous()).array()
            //        .rowwise() * model.weights.row(i)).matrix()
            //    .topRows(3);
            for (int l = 0; l < 3; ++l)
            {
                for (int k = 0; k < tmp.cols(); ++k)
                    positions_d[i_param](l, k) += tmp(l, k) * model.weights(i, k);
            }
        }
    }

    if (model.is_mirrored)
        positions.scale_row(0, -1.);
}

// Inputs:
// model - HandModelEigen
// pose_params 3xN matrix
// corresp - vector<int>
// apply_global - bool, defaults to true
// Outputs:
// positions - 3xN matrix, allocated in this function
// pJ - pointer to memory allocated for the jacobian
void get_skinned_vertex_positions_d(
    const HandModelLightMatrix& model,
    const LightMatrix<double>& pose_params,
    const std::vector<int>& corresp,
    LightMatrix<double>& positions,
    double* pJ,
    bool apply_global)
{
    std::vector<LightMatrix<double>> positions_d; //vector<Matrix3Xd>
    get_skinned_vertex_positions_d_common(model, pose_params, corresp, positions,
        positions_d, pJ);

    LightMatrix<double> Rglob(3, 3);
    Rglob.set_identity();
    if (apply_global)
        apply_global_transform_d(corresp, pose_params, positions, pJ, Rglob);

    // finger parameters
    size_t ncorresp = corresp.size();
    LightMatrix<double> tmp(3, 1);
    for (int i = 0; i < 4 * 5; ++i)
    {
        LightMatrix<double> curr_J(3, ncorresp, &pJ[(6 + i) * 3 * ncorresp], false); // 6 is offset (global params)
        for (int j = 0; j < curr_J.cols(); ++j)
        {
            // curr_J.col(j) = -Rglob * positions_d[i].get_col(corresp[j]);
            mat_mult(Rglob, LightMatrix<double>(3, 1, positions_d[i].get_col_ptr(corresp[j]), false), &tmp);
            curr_J.set_col(j, tmp.get_col(0));
            curr_J.scale_col(j, -1.);
        }
    }
}

// Inputs:
// us - double[2 * corresp.size()]
// model - HandModelEigen
// pose_params 3xN matrix
// corresp - vector<int>
// apply_global - bool, defaults to true
// Outputs:
// positions - 3xN matrix, allocated in this function
// pJ - pointer to memory allocated for the jacobian
void get_skinned_vertex_positions_d(
    const double* const us,
    const HandModelLightMatrix& model,
    const LightMatrix<double>& pose_params,
    const std::vector<int>& corresp,
    LightMatrix<double>& positions,
    double* pJ,
    bool apply_global)
{
    std::vector<LightMatrix<double>> positions_d; //vector<Matrix3Xd>
    get_skinned_vertex_positions_d_common(model, pose_params, corresp, positions,
        positions_d, pJ);

    LightMatrix<double> Rglob(3, 3);
    Rglob.set_identity();
    if (apply_global)
        apply_global_transform_d(us, model.triangles, corresp, pose_params, positions, pJ, Rglob);

    // finger parameters
    size_t ncorresp = corresp.size();
    LightMatrix<double> tmp1(3, 1), tmp2(3, 1);
    for (int i = 0; i < 4 * 5; ++i)
    {
        LightMatrix<double> curr_J(3, ncorresp, &pJ[(6 + i) * 3 * ncorresp], false); // 6 is offset (global params)
        for (int j = 0; j < curr_J.cols(); ++j)
        {
            const auto& verts = model.triangles[corresp[j]].verts;
            const double* const u = &us[2 * j];

            //tmp1 = u[0] * positions_d[i].col(verts[0]) + u[1] * positions_d[i].col(verts[1])
            //    + (1. - u[0] - u[1]) * positions_d[i].col(verts[2]);
            tmp1.set(positions_d[i].get_col(verts[0]));
            tmp1.scale_col(0, u[0]);
            tmp2.set(positions_d[i].get_col(verts[1]));
            tmp2.scale_col(0, u[1]);
            tmp1.add(tmp2);
            tmp2.set(positions_d[i].get_col(verts[2]));
            tmp2.scale_col(0, 1. - u[0] - u[1]);
            tmp1.add(tmp2);

            //curr_J.col(j) = -Rglob * tmp1;
            mat_mult(Rglob, tmp1, &tmp2);
            curr_J.set_col(j, tmp2.get_col(0));
            curr_J.scale_col(j, -1.);
        }
    }
}

// Inputs:
// theta - double[]
// bone_names - vector<string>
// Outputs:
// pose_params - 3xN matrix, allocated in this function
void to_pose_params_d(
    const double* const theta,
    const std::vector<std::string>& bone_names,
    LightMatrix<double>& pose_params)
{
    pose_params.resize(3, bone_names.size() + 3);
    pose_params.fill(0.);

    pose_params.set_col(0, &theta[0]);
    pose_params.set_col(1, 1.);
    pose_params.set_col(2, &theta[3]);

    int i_theta = 6;
    int i_pose_params = 5;
    int n_fingers = 5;
    for (int i_finger = 0; i_finger < n_fingers; ++i_finger)
    {
        for (int i = 2; i <= 4; ++i)
        {
            pose_params(0, i_pose_params) = theta[i_theta++];
            if (i == 2)
            {
                pose_params(1, i_pose_params) = theta[i_theta++];
            }
            i_pose_params++;
        }
        i_pose_params++;
    }
}

// Inputs:
// theta - double[]
// data - HandDataEigen
// Outputs:
// perr - pointer to memory allocated for the objective - double[3 * data.correspondences.size()]
// pJ - pointer to memory allocated for the jacobian
void hand_objective_d(
    const double* const theta,
    const HandDataLightMatrix& data,
    double* perr,
    double* pJ)
{
    LightMatrix<double> pose_params; // Matrix3Xd
    to_pose_params_d(theta, data.model.bone_names, pose_params);

    LightMatrix<double> vertex_positions; // Matrix3Xd
    get_skinned_vertex_positions_d(data.model, pose_params, data.correspondences, vertex_positions, pJ);

    size_t npts = data.correspondences.size();
    //Map<Matrix3Xd> err(perr, 3, npts);
    LightMatrix<double> err(3, npts, perr, false);
    for (size_t i = 0; i < data.correspondences.size(); ++i)
    {
        //err.col(i) = data.points.col(i) - vertex_positions.col(data.correspondences[i]);
        subtract(3, data.points.get_col(i), vertex_positions.get_col(data.correspondences[i]), err.get_col_ptr(i));
    }
}

// Inputs:
// theta - double[]
// us - double[2 * data.correspondences.size()]
// data - HandDataEigen
// Outputs:
// perr - pointer to memory allocated for the objective - double[3 * data.correspondences.size()]
// pJ - pointer to memory allocated for the jacobian
void hand_objective_d(
    const double* const theta,
    const double* const us,
    const HandDataLightMatrix& data,
    double* perr,
    double* pJ)
{
    LightMatrix<double> pose_params; // Matrix3Xd
    to_pose_params_d(theta, data.model.bone_names, pose_params);

    size_t npts = data.correspondences.size();
    LightMatrix<double> vertex_positions; // Matrix3Xd
    get_skinned_vertex_positions_d(us, data.model, pose_params, data.correspondences, vertex_positions, &pJ[2 * 3 * npts]);

    LightMatrix<double> err(3, npts, perr, false);
    LightMatrix<double> du0(3, npts, &pJ[0], false), du1(3, npts, &pJ[3 * npts], false);
    LightMatrix<double> hand_point(3, 1), tmp(3, 1);
    for (size_t i = 0; i < data.correspondences.size(); ++i)
    {
        const auto& verts = data.model.triangles[data.correspondences[i]].verts;
        const double* const u = &us[2 * i];

        subtract(3, vertex_positions.get_col(verts[2]), vertex_positions.get_col(verts[0]), du0.get_col_ptr(i));
        subtract(3, vertex_positions.get_col(verts[2]), vertex_positions.get_col(verts[1]), du1.get_col_ptr(i));

        //hand_point = u[0] * vertex_positions.col(verts[0]) + u[1] * vertex_positions.col(verts[1])
        //    + (1. - u[0] - u[1]) * vertex_positions.col(verts[2]);
        hand_point.set(vertex_positions.get_col(verts[0]));
        hand_point.scale_col(0, u[0]);
        tmp.set(vertex_positions.get_col(verts[1]));
        tmp.scale_col(0, u[1]);
        hand_point.add(tmp);
        tmp.set(vertex_positions.get_col(verts[2]));
        tmp.scale_col(0, 1. - u[0] - u[1]);
        hand_point.add(tmp);

        subtract(3, data.points.get_col(i), hand_point.get_col(0), err.get_col_ptr(i));
    }
}