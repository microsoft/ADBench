#include <cstring>
#include <cstdlib>
#include <cmath>
#include <cfloat>

#include "../../src/cpp/shared/defs.h"

#include "ba_d.h"

void computeZachWeightError_d(double w, double *err, double *J)
{
  *err = 1 - w*w;
  *J = -2 * w;
}

#ifdef DO_CPP
#include "../../src/cpp/shared/matrix.h"
#include "../cpp-common/ba.h" //clean c++ objective function

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

    w_d.noalias() = -rot*theta_d*(theta_inverse*theta_inverse);
    for (int i = 0; i < 3; i++)
      w_d(i, i) += theta_inverse;

    w_cross_X(0) = w(1) * X(2) - w(2) * X(1);
    w_cross_X(1) = w(2) * X(0) - w(0) * X(2);
    w_cross_X(2) = w(0) * X(1) - w(1) * X(0);

    double w_dot_X = w.dot(X);
    double tmp = (1. - costheta) * (w_dot_X);
    tmp_d.noalias() = (1. - costheta)*X.transpose()*w_d +
      w_dot_X*sintheta*theta_d;

    rotatedX.noalias() = costheta*X + sintheta*w_cross_X + tmp*w;

    set_cross_mat(X, M);
    M *= -sintheta;
    for (int i = 0; i < 3; i++)
      M(i, i) = tmp;

    rodri_rot_d.noalias() = (costheta*w_cross_X - sintheta*X)*theta_d +
      M*w_d + w*tmp_d;

    set_cross_mat(w, X_cross);
    rodri_X_d.noalias() = sintheta*X_cross + (1. - costheta)*w*w.transpose();
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
  distort_proj_d.noalias() = (2 * rad_params(0) + 4 * rad_params(1)*rsq)*
    proj*proj.transpose();
  distort_proj_d(0, 0) += L;
  distort_proj_d(1, 1) += L;
  distort_rad_d.col(0) = proj*rsq;
  distort_rad_d.col(1) = distort_rad_d.col(0)*rsq;
  proj *= L;
}

void project_d(
  const double* const cam,
  const double* const X,
  double *proj,
  double *J)
{
  double Xo[3], Xcam[3];
  const double *const rot = &cam[BA_ROT_IDX];
  const double *const C = &cam[BA_C_IDX];
  double f = cam[BA_F_IDX];
  const double *const x0 = &cam[BA_X0_IDX];
  const double *const rad = &cam[BA_RAD_IDX];

  double *Jrot = &J[2 * BA_ROT_IDX];
  double *JC = &J[2 * BA_C_IDX];
  double *Jf = &J[2 * BA_F_IDX];
  double *Jx0 = &J[2 * BA_X0_IDX];
  double *Jrad = &J[2 * BA_RAD_IDX];
  double *JX = &J[2 * BA_NCAMPARAMS];

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
  multiply(2, 2, 1, distort_proj_d, hnorm_right_col, &distort_hnorm_d[4]);

  Jrot.noalias() = f*distort_hnorm_d*rodri_rot_d;
  JC.noalias() = (-f)*distort_hnorm_d*rodri_Xo_d;
  Jf = proj;
  Jx0.setIdentity();
  Jrad = distort_rad_d*f;
  JX = -JC;

  proj = proj*f + x0;
}

void computeReprojError_d(
  const double* const cam,
  const double* const X,
  double w,
  double feat_x,
  double feat_y,
  double *err,
  double *J)
{
  double proj[2];
  project_d(cam, X, proj, J);

  int Jw_idx = 2 * (BA_NCAMPARAMS + 3);
  J[Jw_idx + 0] = (proj[0] - feat_x);
  J[Jw_idx + 1] = (proj[1] - feat_y);
  err[0] = w*J[Jw_idx + 0];
  err[1] = w*J[Jw_idx + 1];
  for (int i = 0; i < 2 * (BA_NCAMPARAMS + 3); i++)
  {
    J[i] *= w;
  }
}

#endif


#ifdef DO_EIGEN

#include "Eigen/Dense"

#include "../cpp-common/ba_eigen.h"

using Eigen::Map;
using Eigen::Vector3d;
using Eigen::Vector2d;
using Eigen::RowVector3d;
using Eigen::RowVector2d;
using Eigen::Matrix2d;
using Eigen::Matrix3d;
typedef Eigen::Matrix<double, 2, 3> Matrix23d;

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

    w_d.noalias() = -rot*theta_d*(theta_inverse*theta_inverse);
    for (int i = 0; i < 3; i++)
      w_d(i, i) += theta_inverse;

    w_cross_X(0) = w(1) * X(2) - w(2) * X(1);
    w_cross_X(1) = w(2) * X(0) - w(0) * X(2);
    w_cross_X(2) = w(0) * X(1) - w(1) * X(0);

    double w_dot_X = w.dot(X);
    double tmp = (1. - costheta) * (w_dot_X);
    tmp_d.noalias() = (1. - costheta)*X.transpose()*w_d +
      w_dot_X*sintheta*theta_d;

    rotatedX.noalias() = costheta*X + sintheta*w_cross_X + tmp*w;

    set_cross_mat(X, M);
    M *= -sintheta;
    for (int i = 0; i < 3; i++)
      M(i, i) = tmp;

    rodri_rot_d.noalias() = (costheta*w_cross_X - sintheta*X)*theta_d +
      M*w_d + w*tmp_d;

    set_cross_mat(w, X_cross);
    rodri_X_d.noalias() = sintheta*X_cross + (1. - costheta)*w*w.transpose();
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
  distort_proj_d.noalias() = (2 * rad_params(0) + 4 * rad_params(1)*rsq)*
    proj*proj.transpose();
  distort_proj_d(0, 0) += L;
  distort_proj_d(1, 1) += L;
  distort_rad_d.col(0) = proj*rsq;
  distort_rad_d.col(1) = distort_rad_d.col(0)*rsq;
  proj *= L;
}

void project_d(
  const double* const cam, 
  const Vector3d& X, 
  Vector2d& proj,
  double *J)
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
  hnorm_right_col *= 1. / (Xcam(2)*Xcam(2));
  Matrix23d distort_hnorm_d;
  distort_hnorm_d.leftCols(2) = distort_proj_d / Xcam(2);
  distort_hnorm_d.col(2).noalias() = distort_proj_d*hnorm_right_col;

  Jrot.noalias() = f*distort_hnorm_d*rodri_rot_d;
  JC.noalias() = (-f)*distort_hnorm_d*rodri_Xo_d;
  Jf = proj;
  Jx0.setIdentity();
  Jrad = distort_rad_d*f;
  JX = -JC;

  proj = proj*f + x0;
}

void computeReprojError_d(
  const double* const cam,
  const double* const X, 
  double w, 
  double feat_x,
  double feat_y, 
  double *err, 
  double *J)
{
  Vector2d proj;
  Map<const Vector3d> X_map(X);
  project_d(cam, X_map, proj, J);

  int Jw_idx = 2 * (BA_NCAMPARAMS + 3);
  J[Jw_idx + 0] = (proj(0) - feat_x);
  J[Jw_idx + 1] = (proj(1) - feat_y);
  err[0] = w*J[Jw_idx + 0];
  err[1] = w*J[Jw_idx + 1];
  for (int i = 0; i < 2 * (BA_NCAMPARAMS + 3); i++)
  {
    J[i] *= w;
  }
}

#endif
