#pragma once

#include <vector>
#include <unordered_map>
#include <string>

#include <Eigen\Dense>
#include <Eigen\StdVector>

#include "../defs.h"

using std::vector;
using std::unordered_map;
using std::string;
using Eigen::Map;
using Eigen::Vector3d;
using Eigen::Matrix3Xd;
using Eigen::Matrix4d;
using Eigen::aligned_allocator;
using Eigen::AngleAxisd;
using Eigen::Matrix3d;
using Eigen::MatrixXd;

void angle_axis_to_rotation_matrix_d(
  const Vector3d& angle_axis,
  Matrix3d *R,
  vector<Matrix3d> *pdR)
{
  auto& dR = *pdR;
  double sqnorm = angle_axis.squaredNorm();
  double norm = sqrt(sqnorm);
  if (norm < .0001)
  {
    R->setIdentity();
    for (int i = 0; i < 3; i++)
      dR[i].setZero();
    return;
  }
  double inv_norm = 1. / norm;
  double inv_sqnorm = 1. / sqnorm;
  Vector3d d_norm = angle_axis * inv_norm;

  double x = angle_axis(0) * inv_norm;
  double y = angle_axis(1) * inv_norm;
  double z = angle_axis(2) * inv_norm;
  Vector3d dx, dy, dz;
  for (int i = 0; i < 3; i++)
  {
    dx(i) = -angle_axis(0)*d_norm(i) * inv_sqnorm;
    dy(i) = -angle_axis(1)*d_norm(i) * inv_sqnorm;
    dz(i) = -angle_axis(2)*d_norm(i) * inv_sqnorm;
  }
  dx(0) += norm*inv_sqnorm;
  dy(1) += norm*inv_sqnorm;
  dz(2) += norm*inv_sqnorm;

  double s = sin(norm);
  double c = cos(norm);
  Vector3d dc, ds;
  ds = c*d_norm;
  dc = -s*d_norm;

  *R << x*x + (1 - x*x)*c, x*y*(1 - c) - z*s, x*z*(1 - c) + y*s,
    x*y*(1 - c) + z*s, y*y + (1 - y*y)*c, y*z*(1 - c) - x*s,
    x*z*(1 - c) - y*s, z*y*(1 - c) + x*s, z*z + (1 - z*z)*c;

  for (int i = 0; i < 3; i++)
  {
    dR[i] << 2 * x*dx(i) - 2 * x*dx(i)*c + (1 - x*x)*dc(i),
      dx(i)*y*(1 - c) + x*dy(i)*(1 - c) - x*y*dc(i) - dz(i)*s - z*ds(i),
      dx(i)*z*(1 - c) + x*dz(i)*(1 - c) - x*z*dc(i) + dy(i)*s + y*ds(i),
      dx(i)*y*(1 - c) + x*dy(i)*(1 - c) - x*y*dc(i) + dz(i)*s + z*ds(i),
      2 * y*dy(i) - 2 * y*dy(i)*c + (1 - y*y)*dc(i),
      dy(i)*z*(1 - c) + y*dz(i)*(1 - c) - y*z*dc(i) - dx(i)*s - x*ds(i),
      dx(i)*z*(1 - c) + x*dz(i)*(1 - c) - x*z*dc(i) - dy(i)*s - y*ds(i),
      dz(i)*y*(1 - c) + z*dy(i)*(1 - c) - z*y*dc(i) + dx(i)*s + x*ds(i),
      2 * z*dz(i) - 2 * z*dz(i)*c + (1 - z*z)*dc(i);
  }
}

void apply_global_transform_d(
  const vector<int>& corresp,
  const Matrix3Xd& pose_params,
  Matrix3Xd* ppositions,
  double *pJ,
  Matrix3d *pR)
{
  auto& R = *pR;
  auto& positions = *ppositions;
  vector<Matrix3d> dR(3);
  const Vector3d& global_rotation = pose_params.col(0);
  angle_axis_to_rotation_matrix_d(global_rotation, &R, &dR);
  R.noalias() = (R.array().rowwise() * pose_params.col(1).transpose().array()).matrix();
  for (int i = 0; i < 3; i++)
    dR[i].noalias() = (dR[i].array().rowwise() * pose_params.col(1).transpose().array()).matrix();

  // global rotation
  size_t npts = corresp.size();
  for (int i_param = 0; i_param < 3; i_param++)
  {
    Map<Matrix3Xd> J_glob_rot(&pJ[i_param * 3 * npts], 3, npts);
    for (size_t i_pt = 0; i_pt < npts; i_pt++)
    {
      J_glob_rot.col(i_pt).noalias() = -dR[i_param] * positions.col(corresp[i_pt]);
    }
  }

  // global translation
  Map<MatrixXd> J_glob_translation(&pJ[3 * 3 * npts], 3 * npts, 3);
  for (size_t i = 0; i < npts; i++)
  {
    J_glob_translation.middleRows(i * 3, 3).setIdentity();
  }
  J_glob_translation *= -1.;

  positions = (R * positions).colwise() + pose_params.col(2);
}

void apply_global_transform_d(
  const double* const us,
  const vector<Triangle>& triangles,
  const vector<int>& corresp,
  const Matrix3Xd& pose_params,
  Matrix3Xd* ppositions,
  double *pJ,
  Matrix3d *pR)
{
  auto& R = *pR;
  auto& positions = *ppositions;
  vector<Matrix3d> dR(3);
  const Vector3d& global_rotation = pose_params.col(0);
  angle_axis_to_rotation_matrix_d(global_rotation, &R, &dR);
  R.noalias() = (R.array().rowwise() * pose_params.col(1).transpose().array()).matrix();
  for (int i = 0; i < 3; i++)
    dR[i].noalias() = (dR[i].array().rowwise() * pose_params.col(1).transpose().array()).matrix();

  // global rotation
  size_t npts = corresp.size();
  for (int i_param = 0; i_param < 3; i_param++)
  {
    Map<Matrix3Xd> J_glob_rot(&pJ[i_param * 3 * npts], 3, npts);
    for (size_t i_pt = 0; i_pt < npts; i_pt++)
    {
      const auto& verts = triangles[corresp[i_pt]].verts;
      const double* const u = &us[2 * i_pt];

      Vector3d tmp = u[0] * positions.col(verts[0]) + u[1] * positions.col(verts[1])
        + (1. - u[0] - u[1])*positions.col(verts[2]);

      J_glob_rot.col(i_pt).noalias() = -dR[i_param] * tmp;
    }
  }

  // global translation
  Map<MatrixXd> J_glob_translation(&pJ[3 * 3 * npts], 3 * npts, 3);
  for (size_t i = 0; i < npts; i++)
  {
    J_glob_translation.middleRows(i * 3, 3).setIdentity();
  }
  J_glob_translation *= -1.;

  positions = (R * positions).colwise() + pose_params.col(2);
}

void relatives_to_absolutes_d(
  const avector<Matrix4d>& relatives,
  const avector<Matrix4d>& relatives_d,
  const vector<int>& parents,
  avector<Matrix4d>* pabsolutes,
  vector<avector<Matrix4d>>* pabsolutes_d)
{
  auto& absolutes = *pabsolutes;
  auto& absolutes_d = *pabsolutes_d;
  absolutes.resize(parents.size());
  absolutes_d.resize(parents.size());
  int rel_d_tail = 0;
  for (size_t i = 0; i < parents.size(); i++)
  {
    if (parents[i] == -1)
      absolutes[i].noalias() = relatives[i];
    else
      absolutes[i].noalias() = absolutes[parents[i]] * relatives[i];

    int n_finger_bone = (i - 1) % 4;
    if (i > 0 && i < parents.size() - 1 && n_finger_bone > 0)
    {
      absolutes_d[i].resize(n_finger_bone + 1);
      int curr_tail = 0;

      for (const auto& absolute_d_parent : absolutes_d[parents[i]])
        absolutes_d[i][curr_tail++].noalias() = absolute_d_parent * relatives[i];

      absolutes_d[i][curr_tail++].noalias() = absolutes[parents[i]] * relatives_d[rel_d_tail++];
      if (n_finger_bone == 1)
        absolutes_d[i][curr_tail++].noalias() = absolutes[parents[i]] * relatives_d[rel_d_tail++];
    }
  }
}

void euler_angles_to_rotation_matrix(
  const Vector3d& xzy,
  Matrix3d *pR,
  Matrix3d *pdR0 = nullptr,
  Matrix3d *pdR1 = nullptr)
{
  double tx = xzy(0), ty = xzy(2), tz = xzy(1);
  Matrix3d Rx = Matrix3d::Identity(),
    Ry = Matrix3d::Identity(),
    Rz = Matrix3d::Identity();
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

  Matrix3d RzRy = Rz*Ry;
  if (pdR0)
  {
    Matrix3d dRx = Matrix3d::Zero();
    dRx(1, 1) = -Rx(2, 1);
    dRx(2, 1) = Rx(1, 1);
    dRx(1, 2) = -dRx(2, 1);
    dRx(2, 2) = dRx(1, 1);
    pdR0->noalias() = RzRy * dRx;
  }
  if (pdR1)
  {
    Matrix3d dRz = Matrix3d::Zero();
    dRz(0, 0) = -Rz(1, 0);
    dRz(1, 0) = Rz(0, 0);
    dRz(0, 1) = -dRz(1, 0);
    dRz(1, 1) = dRz(0, 0);
    pdR1->noalias() = dRz * Ry * Rx;
  }

  pR->noalias() = RzRy * Rx;
}

void get_posed_relatives_d(
  const HandModelEigen& model,
  const Matrix3Xd& pose_params,
  avector<Matrix4d>* prelatives,
  avector<Matrix4d>* prelatives_d)
{
  auto& relatives = *prelatives;
  auto& relatives_d = *prelatives_d;
  relatives.resize(model.base_relatives.size());
  relatives_d.resize(4 * 5); // 4 parameters in every finger

  int offset = 3;
  int tail = 0;
  for (size_t i = 0; i < model.bone_names.size(); i++)
  {
    Matrix4d tr = Matrix4d::Identity();

    Matrix3d R;
    int n_finger_bone = (i-1) % 4;
    if (i == 0 || i == model.bone_names.size()-1 || n_finger_bone == 0)
    {
      euler_angles_to_rotation_matrix(pose_params.col(i + offset), &R);
    }
    else
    {
      Matrix4d dtr0 = Matrix4d::Zero();
      Matrix3d dR0;
      if (n_finger_bone == 1)
      {
        Matrix4d dtr1 = Matrix4d::Zero();
        Matrix3d dR1;
        euler_angles_to_rotation_matrix(pose_params.col(i + offset), &R, &dR0, &dR1);
        dtr1.block(0, 0, 3, 3) = dR1;
        relatives_d[tail + 1].noalias() = model.base_relatives[i] * dtr1;
      }
      else
        euler_angles_to_rotation_matrix(pose_params.col(i + offset), &R, &dR0);
      dtr0.block(0, 0, 3, 3) = dR0;
      relatives_d[tail++].noalias() = model.base_relatives[i] * dtr0;
      if (n_finger_bone == 1)
        tail++;
    }
    tr.block(0, 0, 3, 3) = R;

    relatives[i].noalias() = model.base_relatives[i] * tr;
  }
}

void get_skinned_vertex_positions_d_common(
  const HandModelEigen& model,
  const Matrix3Xd& pose_params,
  const vector<int>& corresp,
  Matrix3Xd* positions,
  vector<Matrix3Xd> *positions_d,
  double *pJ,
  bool apply_global = true)
{
  avector<Matrix4d> relatives, absolutes, transforms;
  avector<Matrix4d> relatives_d;
  vector<avector<Matrix4d>> absolutes_d, transforms_d;
  get_posed_relatives_d(model, pose_params, &relatives, &relatives_d);
  relatives_to_absolutes_d(relatives, relatives_d, model.parents, &absolutes, &absolutes_d);

  // Get bone transforms.
  transforms.resize(absolutes.size());
  transforms_d.resize(absolutes.size());
  for (size_t i = 0; i < absolutes.size(); i++)
  {
    transforms[i].noalias() = absolutes[i] * model.inverse_base_absolutes[i];
    transforms_d[i].resize(absolutes_d[i].size());
    for (size_t j = 0; j < absolutes_d[i].size(); j++)
      transforms_d[i][j].noalias() = absolutes_d[i][j] * model.inverse_base_absolutes[i];
  }

  // Transform vertices by necessary transforms. + apply skinning
  *positions = Matrix3Xd::Zero(3, model.base_positions.cols());
  positions_d->resize(4 * 5, Matrix3Xd::Zero(3, model.base_positions.cols()));
  for (int i = 0; i < (int)transforms.size(); i++)
  {
    *positions +=
      ((transforms[i] * model.base_positions.colwise().homogeneous()).array()
        .rowwise() * model.weights.row(i)).matrix()
      .topRows(3);

    int i_finger = (i - 1) / 4;
    for (int j = 0; j < (int)transforms_d[i].size(); j++)
    {
      int i_param = j + 4 * i_finger;
      (*positions_d)[i_param] +=
        ((transforms_d[i][j] * model.base_positions.colwise().homogeneous()).array()
          .rowwise() * model.weights.row(i)).matrix()
        .topRows(3);
    }
  }

  if (model.is_mirrored)
    positions->row(0) = -positions->row(0);
}

void get_skinned_vertex_positions_d(
  const HandModelEigen& model,
  const Matrix3Xd& pose_params,
  const vector<int>& corresp,
  Matrix3Xd* positions,
  double *pJ,
  bool apply_global = true)
{
  vector<Matrix3Xd> positions_d;
  get_skinned_vertex_positions_d_common(model, pose_params, corresp, positions,
    &positions_d, pJ, apply_global);

  Matrix3d Rglob = Matrix3d::Identity();
  if (apply_global)
    apply_global_transform_d(corresp, pose_params, positions, pJ, &Rglob);

  // finger parameters
  size_t ncorresp = corresp.size();
  for (int i = 0; i < 4 * 5; i++)
  {
    Map<Matrix3Xd> curr_J(&pJ[(6 + i) * 3 * ncorresp], 3, ncorresp);// 6 is offset (global params)
    for (int j = 0; j < curr_J.cols(); j++)
    {
      curr_J.col(j).noalias() = -Rglob * positions_d[i].col(corresp[j]);
    }
  }
}

void get_skinned_vertex_positions_d(
  const double* const us,
  const HandModelEigen& model,
  const Matrix3Xd& pose_params,
  const vector<int>& corresp,
  Matrix3Xd* positions,
  double *pJ,
  bool apply_global = true)
{
  vector<Matrix3Xd> positions_d;

  get_skinned_vertex_positions_d_common(model, pose_params, corresp, positions, 
    &positions_d, pJ, apply_global);

  Matrix3d Rglob = Matrix3d::Identity();
  if (apply_global)
    apply_global_transform_d(us, model.triangles, corresp, pose_params, positions, pJ, &Rglob);

  // finger parameters
  size_t ncorresp = corresp.size();
  Vector3d tmp;
  for (int i = 0; i < 4 * 5; i++)
  {
    Map<Matrix3Xd> curr_J(&pJ[(6 + i) * 3 * ncorresp], 3, ncorresp); // 6 is offset (global params)
    for (int j = 0; j < curr_J.cols(); j++)
    {
      const auto& verts = model.triangles[corresp[j]].verts;
      const double* const u = &us[2 * j];

      tmp = u[0] * positions_d[i].col(verts[0]) + u[1] * positions_d[i].col(verts[1])
        + (1. - u[0] - u[1])*positions_d[i].col(verts[2]);

      curr_J.col(j).noalias() = -Rglob * tmp;
    }
  }
}

void to_pose_params_d(const double* const theta,
  const vector<string>& bone_names,
  Matrix3Xd *ppose_params)
{
  auto& pose_params = *ppose_params;
  pose_params.resize(3, bone_names.size() + 3);
  pose_params.setZero();

  pose_params.col(0) = Map<const Vector3d>(&theta[0]);
  pose_params.col(1).setOnes();
  pose_params.col(2) = Map<const Vector3d>(&theta[3]);

  int i_theta = 6;
  int i_pose_params = 5;
  int n_fingers = 5;
  for (int i_finger = 0; i_finger < n_fingers; i_finger++)
  {
    for (int i = 2; i <= 4; i++)
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

void hand_objective_d(
  const double* const theta,
  const HandDataEigen& data,
  double *perr,
  double *pJ)
{
  Matrix3Xd pose_params;
  to_pose_params_d(theta, data.model.bone_names, &pose_params);

  Matrix3Xd vertex_positions;
  get_skinned_vertex_positions_d(data.model, pose_params, data.correspondences, &vertex_positions, pJ);

  size_t npts = data.correspondences.size();
  Map<Matrix3Xd> err(perr, 3, npts);
  for (int i = 0; i < data.correspondences.size(); i++)
  {
    err.col(i) = data.points.col(i) - vertex_positions.col(data.correspondences[i]);
  }
}

void hand_objective_d(
  const double* const theta,
  const double* const us,
  const HandDataEigen& data,
  double *perr,
  double *pJ)
{
  Matrix3Xd pose_params;
  to_pose_params_d(theta, data.model.bone_names, &pose_params);

  size_t npts = data.correspondences.size();
  Matrix3Xd vertex_positions;
  get_skinned_vertex_positions_d(us, data.model, pose_params, data.correspondences, &vertex_positions, &pJ[2*3*npts]);

  Map<Matrix3Xd> err(perr, 3, npts);
  Map<Matrix3Xd> du0(&pJ[0], 3, npts), du1(&pJ[3*npts], 3, npts);
  Vector3d hand_point;
  for (int i = 0; i < data.correspondences.size(); i++)
  {
    const auto& verts = data.model.triangles[data.correspondences[i]].verts;
    const double* const u = &us[2 * i];

    du0.col(i) = -(vertex_positions.col(verts[0]) - vertex_positions.col(verts[2]));
    du1.col(i) = -(vertex_positions.col(verts[1]) - vertex_positions.col(verts[2]));

    hand_point = u[0] * vertex_positions.col(verts[0]) + u[1] * vertex_positions.col(verts[1])
      + (1. - u[0] - u[1])*vertex_positions.col(verts[2]);
    err.col(i) = data.points.col(i) - hand_point;
  }
}