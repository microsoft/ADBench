#include <cstring>
#include <cstdlib>
#include <cmath>
#include <cfloat>

#include "../../shared/defs.h"
#include "../../shared/matrix.h"
#include "../../shared/ba_eigen.h"
#include "ba_d.h"

#include "Eigen/Dense"

using Eigen::Map;
using Eigen::Vector3d;
using Eigen::Vector2d;
using Eigen::RowVector3d;
using Eigen::RowVector2d;
using Eigen::Matrix2d;
using Eigen::Matrix3d;
typedef Eigen::Matrix<double, 2, 3> Matrix23d;

void compute_zach_weight_error_d(double w, double* err, double* J)
{
    *err = 1 - w * w;
    *J = -2 * w;
}

// Arguments:
// v - double[3]
// M - double[9] (3x3 col-major matrix)
void set_cross_mat(
    const double* v,
    double* M)
{
    //      0.    -v[2]   v[1]
    // M =  v[2]   0.    -v[0]
    //     -v[1]   v[0]   0.
    M[0 * 3 + 0] = 0.;    M[1 * 3 + 0] = -v[2]; M[2 * 3 + 0] = v[1];
    M[0 * 3 + 1] = v[2];  M[1 * 3 + 1] = 0.;    M[2 * 3 + 1] = -v[0];
    M[0 * 3 + 2] = -v[1]; M[1 * 3 + 2] = v[0];  M[2 * 3 + 2] = 0.;
}

// Adapted from the version using Eigen.
// Arguments:
// rot - double[3]
// X - double[3]
// rotatedX - double[3]
// rodri_rot_d - double[9] (3x3 col-major matrix)
// rodri_X_d - double[9] (3x3 col-major matrix)
void rodrigues_rotate_point_d(
    const double* rot,
    const double* X,
    double* rotatedX,
    double* rodri_rot_d,
    double* rodri_X_d)
{
    double sqtheta = sqnorm(3, rot);
    if (sqtheta != 0.)
    {
        double w[3], w_cross_X[3], acc[3], acc2[3]; // Vector3d
        double tmp_d[3], theta_d_scaled[3], x_scaled[3]; // RowVector3d
        double w_d[9], M[9], X_cross[9], accm[9]; // Matrix3d

        double theta = sqrt(sqtheta);
        double costheta = cos(theta);
        double sintheta = sin(theta);
        double theta_inverse = 1.0 / theta;

        scale(3, theta_inverse, rot, w);

        scale(3, -theta_inverse * theta_inverse, w, tmp_d);
        mat_mul(3, 1, 3, rot, tmp_d, w_d);
        for (int i = 0; i < 3; i++)
            w_d[i * 3 + i] += theta_inverse;

        cross(w, X, w_cross_X);

        double w_dot_X = dot(3, w, X);
        double tmp = (1. - costheta) * (w_dot_X);
        scale(3, 1. - costheta, X, x_scaled);
        mat_mul(1, 3, 3, x_scaled, w_d, tmp_d);
        scale(3, w_dot_X * sintheta, w, theta_d_scaled);
        add_to(3, tmp_d, theta_d_scaled);

        scale(3, costheta, X, rotatedX);
        scale(3, sintheta, w_cross_X, acc);
        add_to(3, rotatedX, acc);
        scale(3, tmp, w, acc);
        add_to(3, rotatedX, acc);

        set_cross_mat(X, M);
        for (int i = 0; i < 9; ++i)
            M[i] *= -sintheta;
        for (int i = 0; i < 3; i++)
            M[i * 3 + i] = tmp;

        scale(3, costheta, w_cross_X, acc);
        scale(3, -sintheta, X, acc2);
        add_to(3, acc, acc2);
        mat_mul(3, 1, 3, acc, w, rodri_rot_d);
        mat_mul(3, 3, 3, M, w_d, accm);
        for (int i = 0; i < 9; ++i)
            rodri_rot_d[i] += accm[i];
        mat_mul(3, 1, 3, w, tmp_d, accm);
        add_to(9, rodri_rot_d, accm);

        set_cross_mat(w, X_cross);
        for (int i = 0; i < 9; ++i)
            rodri_X_d[i] = X_cross[i] * sintheta;
        scale(3, 1. - costheta, w, acc);
        mat_mul(3, 1, 3, acc, w, accm);
        add_to(9, rodri_X_d, accm);
        for (int i = 0; i < 3; i++)
            rodri_X_d[i * 3 + i] += costheta;
    }
    else
    {
        set_cross_mat(X, rodri_rot_d);
        for (int i = 0; i < 9; ++i)
            rodri_rot_d[i] *= -1;
        set_cross_mat(rot, rodri_X_d);
        mat_mul(3, 3, 1, rodri_X_d, X, rotatedX);
        add_to(3, rotatedX, X);
        for (int i = 0; i < 3; i++)
            rodri_X_d[i * 3 + i] += 1;
    }
}

// Arguments:
// rad_params - double[2]
// proj - double[2]
// distort_proj_d - double[4] (2x2 col-major matrix)
// distort_rad_d - double[4] (2x2 col-major matrix)
void radial_distort_d(
    const double* rad_params,
    double* proj,
    double* distort_proj_d,
    double* distort_rad_d)
{
    double rsq = sqnorm(2, proj);
    double L = 1 + rad_params[0] * rsq + rad_params[1] * rsq * rsq;
    double distort_proj_d_coef = 2 * rad_params[0] + 4 * rad_params[1] * rsq;
    distort_proj_d[0 * 2 + 0] = distort_proj_d_coef * proj[0] * proj[0] + L;
    distort_proj_d[1 * 2 + 0] = distort_proj_d_coef * proj[0] * proj[1];
    distort_proj_d[0 * 2 + 1] = distort_proj_d_coef * proj[1] * proj[0];
    distort_proj_d[1 * 2 + 1] = distort_proj_d_coef * proj[1] * proj[1] + L;
    distort_rad_d[0 * 2 + 0] = rsq * proj[0];
    distort_rad_d[0 * 2 + 1] = rsq * proj[1];
    distort_rad_d[1 * 2 + 0] = rsq * distort_rad_d[0 * 2 + 0];
    distort_rad_d[1 * 2 + 1] = rsq * distort_rad_d[0 * 2 + 1];
    proj[0] *= L;
    proj[1] *= L;
}

// Arguments:
// cam - double[BA_NCAMPARAMS]
// X - double[3]
// proj - double[2]
// J - 2 x (BA_NCAMPARAMS+3+1) in column major
void project_d(
    const double* const cam,
    const double* const X,
    double* proj,
    double* J)
{
    double Xo[3], Xcam[3];
    const double* const rot = &cam[BA_ROT_IDX];
    const double* const C = &cam[BA_C_IDX];
    double f = cam[BA_F_IDX];
    const double* const x0 = &cam[BA_X0_IDX];
    const double* const rad = &cam[BA_RAD_IDX];

    double* Jrot = &J[2 * BA_ROT_IDX];
    double* JC = &J[2 * BA_C_IDX];
    double* Jf = &J[2 * BA_F_IDX];
    double* Jx0 = &J[2 * BA_X0_IDX];
    double* Jrad = &J[2 * BA_RAD_IDX];
    double* JX = &J[2 * BA_NCAMPARAMS];

    subtract(3, X, C, Xo);

    double rodri_rot_d[9], rodri_Xo_d[9];
    rodrigues_rotate_point_d(rot, Xo, Xcam, rodri_rot_d,
        rodri_Xo_d);

    p2e(Xcam, proj);

    double distort_proj_d[4], distort_rad_d[4];
    radial_distort_d(rad, proj, distort_proj_d, distort_rad_d);

    double hnorm_right_col[2];
    double tmp = 1. / (Xcam[2] * Xcam[2]);
    hnorm_right_col[0] = -Xcam[0] * tmp;
    hnorm_right_col[1] = -Xcam[1] * tmp;
    double distort_hnorm_d[6];

    for (int i = 0; i < 4; i++)
        distort_hnorm_d[i] = distort_proj_d[i] / Xcam[2];
    distort_hnorm_d[2 * 2 + 0] = distort_proj_d[0 * 2 + 0] * hnorm_right_col[0] + distort_proj_d[1 * 2 + 0] * hnorm_right_col[1];
    distort_hnorm_d[2 * 2 + 1] = distort_proj_d[0 * 2 + 1] * hnorm_right_col[0] + distort_proj_d[1 * 2 + 1] * hnorm_right_col[1];

    mat_mul(2, 3, 3, distort_hnorm_d, rodri_rot_d, Jrot);
    for (int i = 0; i < 6; ++i)
        Jrot[i] *= f;

    mat_mul(2, 3, 3, distort_hnorm_d, rodri_Xo_d, JC);
    for (int i = 0; i < 6; ++i)
        JC[i] *= -f;
    Jf[0] = proj[0];
    Jf[1] = proj[1];

    // Initializind Jx0 to identity
    Jx0[0] = 1.;
    Jx0[1] = 0.;
    Jx0[2] = 0.;
    Jx0[3] = 1.;
    for (int i = 0; i < 4; ++i)
        Jrad[i] = distort_rad_d[i] * f;
    for (int i = 0; i < 6; ++i)
        JX[i] = -JC[i];

    proj[0] = proj[0] * f + x0[0];
    proj[1] = proj[1] * f + x0[1];
}

// Arguments:
// cam - double[BA_NCAMPARAMS]
// X - double[3]
// w, feat_x, feat_y - double
// err - double[2]
// J - 2 x (BA_NCAMPARAMS+3+1) in column major
void compute_reproj_error_d(
    const double* const cam,
    const double* const X,
    double w,
    double feat_x,
    double feat_y,
    double* err,
    double* J)
{
    double proj[2];
    project_d(cam, X, proj, J);

    int Jw_idx = 2 * (BA_NCAMPARAMS + 3);
    J[Jw_idx + 0] = (proj[0] - feat_x);
    J[Jw_idx + 1] = (proj[1] - feat_y);
    err[0] = w * J[Jw_idx + 0];
    err[1] = w * J[Jw_idx + 1];
    for (int i = 0; i < 2 * (BA_NCAMPARAMS + 3); i++)
    {
        J[i] *= w;
    }
}

void set_cross_mat(
    const Vector3d& v,
    Matrix3d& M)
{
    M(0, 0) = 0.;	 M(0, 1) = -v(2); M(0, 2) = v(1);
    M(1, 0) = v(2);  M(1, 1) = 0;     M(1, 2) = -v(0);
    M(2, 0) = -v(1); M(2, 1) = v(0);  M(2, 2) = 0;
}

void rodrigues_rotate_point_d(
    const Vector3d& rot,
    const Vector3d& X,
    Vector3d& rotatedX,
    Matrix3d& rodri_rot_d,
    Matrix3d& rodri_X_d)
{
    double sqtheta = rot.squaredNorm();
    if (sqtheta != 0.)
    {
        Vector3d w, w_cross_X;
        RowVector3d theta_d, tmp_d;
        Matrix3d w_d, M, X_cross;
        double theta = sqrt(sqtheta);

        double costheta = cos(theta);
        double sintheta = sin(theta);
        double theta_inverse = 1.0 / theta;

        w.noalias() = rot * theta_inverse;
        theta_d = w.transpose();

        w_d.noalias() = -rot * theta_d * (theta_inverse * theta_inverse);
        for (int i = 0; i < 3; i++)
            w_d(i, i) += theta_inverse;

        w_cross_X(0) = w(1) * X(2) - w(2) * X(1);
        w_cross_X(1) = w(2) * X(0) - w(0) * X(2);
        w_cross_X(2) = w(0) * X(1) - w(1) * X(0);

        double w_dot_X = w.dot(X);
        double tmp = (1. - costheta) * (w_dot_X);
        tmp_d.noalias() = (1. - costheta) * X.transpose() * w_d +
            w_dot_X * sintheta * theta_d;

        rotatedX.noalias() = costheta * X + sintheta * w_cross_X + tmp * w;

        set_cross_mat(X, M);
        M *= -sintheta;
        for (int i = 0; i < 3; i++)
            M(i, i) = tmp;

        rodri_rot_d.noalias() = (costheta * w_cross_X - sintheta * X) * theta_d +
            M * w_d + w * tmp_d;

        set_cross_mat(w, X_cross);
        rodri_X_d.noalias() = sintheta * X_cross + (1. - costheta) * w * w.transpose();
        for (int i = 0; i < 3; i++)
            rodri_X_d(i, i) += costheta;
    }
    else
    {
        set_cross_mat(X, rodri_rot_d);
        rodri_rot_d *= -1;
        Matrix3d rot_cross;
        set_cross_mat(rot, rot_cross);
        rotatedX.noalias() = X + rot_cross * X;
        rodri_X_d = Matrix3d::Identity() + rot_cross;
    }
}

void radial_distort_d(
    const Vector2d& rad_params,
    Vector2d& proj,
    Matrix2d& distort_proj_d,
    Matrix2d& distort_rad_d)
{
    double rsq = proj.squaredNorm();
    double L = 1 + rad_params(0) * rsq + rad_params(1) * rsq * rsq;
    distort_proj_d.noalias() = (2 * rad_params(0) + 4 * rad_params(1) * rsq) *
        proj * proj.transpose();
    distort_proj_d(0, 0) += L;
    distort_proj_d(1, 1) += L;
    distort_rad_d.col(0) = proj * rsq;
    distort_rad_d.col(1) = distort_rad_d.col(0) * rsq;
    proj *= L;
}

void project_d(
    const double* const cam,
    const Vector3d& X,
    Vector2d& proj,
    double* J)
{
    Vector3d Xo, Xcam;
    Map<const Vector3d> rot(&cam[BA_ROT_IDX]);
    Map<const Vector3d> C(&cam[BA_C_IDX]);
    double f = cam[BA_F_IDX];
    Map<const Vector2d> x0(&cam[BA_X0_IDX]);
    Map<const Vector2d> rad(&cam[BA_RAD_IDX]);

    Map<Matrix23d> Jrot(&J[2 * BA_ROT_IDX]);
    Map<Matrix23d> JC(&J[2 * BA_C_IDX]);
    Map<Vector2d> Jf(&J[2 * BA_F_IDX]);
    Map<Matrix2d> Jx0(&J[2 * BA_X0_IDX]);
    Map<Matrix2d> Jrad(&J[2 * BA_RAD_IDX]);
    Map<Matrix23d> JX(&J[2 * BA_NCAMPARAMS]);

    Xo = X - C;

    Matrix3d rodri_rot_d, rodri_Xo_d;
    rodrigues_rotate_point_d(rot, Xo, Xcam, rodri_rot_d,
        rodri_Xo_d);

    proj = Xcam.hnormalized();

    Matrix2d distort_proj_d, distort_rad_d;
    radial_distort_d(rad, proj, distort_proj_d, distort_rad_d);

    Vector2d hnorm_right_col = -Xcam.topRows(2);
    hnorm_right_col *= 1. / (Xcam(2) * Xcam(2));
    Matrix23d distort_hnorm_d;
    distort_hnorm_d.leftCols(2) = distort_proj_d / Xcam(2);
    distort_hnorm_d.col(2).noalias() = distort_proj_d * hnorm_right_col;

    Jrot.noalias() = f * distort_hnorm_d * rodri_rot_d;
    JC.noalias() = (-f) * distort_hnorm_d * rodri_Xo_d;
    Jf = proj;
    Jx0.setIdentity();
    Jrad = distort_rad_d * f;
    JX = -JC;

    proj = proj * f + x0;
}
