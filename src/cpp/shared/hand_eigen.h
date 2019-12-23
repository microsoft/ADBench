// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once

#include <vector>
#include <unordered_map>
#include <string>

#include <Eigen/Dense>
#include <Eigen/StdVector>

#include "utils.h"
#include "hand_eigen_model.h"

using Eigen::Map;
using Eigen::Vector3d;
using Eigen::Matrix3Xd;
using Eigen::Matrix4d;
using Eigen::aligned_allocator;
using Eigen::AngleAxis;
template<typename T>
using Matrix3X = Eigen::Matrix<T, 3, -1>;
template<typename T>
using Matrix3 = Eigen::Matrix<T, 3, 3>;
template<typename T>
using Matrix4 = Eigen::Matrix<T, 4, 4>;
template<typename T>
using Vector3 = Eigen::Matrix<T, 3, 1>;

template<typename T>
using vector_of_Matrix4 = std::vector<Matrix4<T>, Eigen::aligned_allocator<Matrix4<T>>>;


////////////////////////////////////////////////////////////
//////////////////// Declarations //////////////////////////
////////////////////////////////////////////////////////////

// theta: 26 [global rotation, global translation, finger parameters (4*5)]
// data: data measurements and hand model
// err: 3*number_of_correspondences
template<typename T>
void hand_objective(
  const T* const theta,
  const HandDataEigen& data,
  T *err);

// theta: 26 [global rotation, global translation, finger parameters (4*5)]
// us: 2*number_of_correspondences
// data: data measurements and hand model
// err: 3*number_of_correspondences
template<typename T>
void hand_objective(
  const T* const theta,
  const T* const us,
  const HandDataEigen& data,
  T *err);

////////////////////////////////////////////////////////////
//////////////////// Definitions ///////////////////////////
////////////////////////////////////////////////////////////

template<typename T>
void angle_axis_to_rotation_matrix(
  const Vector3<T>& angle_axis,
  Matrix3<T> *R)
{
  T norm = angle_axis.norm();
  if (norm < .0001)
  {
    R->setIdentity();
    return;
  }

  T x = angle_axis(0) / norm;
  T y = angle_axis(1) / norm;
  T z = angle_axis(2) / norm;
  
  T s = sin(norm);
  T c = cos(norm);

  *R << x*x + (1 - x*x)*c, x*y*(1 - c) - z*s, x*z*(1 - c) + y*s,
    x*y*(1 - c) + z*s, y*y + (1 - y*y)*c, y*z*(1 - c) - x*s,
    x*z*(1 - c) - y*s, z*y*(1 - c) + x*s, z*z + (1 - z*z)*c;
}

template<typename T>
void apply_global_transform(
  const Matrix3X<T>& pose_params,
  Matrix3X<T>* positions)
{
  Matrix3<T> R;
  const Vector3<T>& global_rotation = pose_params.col(0);
  angle_axis_to_rotation_matrix(global_rotation, &R);
  R.noalias() = (R.array().rowwise() * pose_params.col(1).transpose().array()).matrix();
  
  *positions = (R * (*positions)).colwise() + pose_params.col(2);
}

template<typename T>
void relatives_to_absolutes(
  const vector_of_Matrix4<T>& relatives,
  const std::vector<int>& parents,
  vector_of_Matrix4<T>* pabsolutes)
{
  auto& absolutes = *pabsolutes;
  absolutes.resize(parents.size());
  for (size_t i = 0; i < parents.size(); i++)
  {
    if (parents[i] == -1)
      absolutes[i].noalias() = relatives[i];
    else
      absolutes[i].noalias() = absolutes[parents[i]] * relatives[i];
  }
}

template<typename T>
void get_posed_relatives(
  const HandModelEigen& model,
  const Matrix3X<T>& pose_params,
  vector_of_Matrix4<T>* prelatives)
{
  auto& relatives = *prelatives;
  relatives.resize(model.base_relatives.size());

  int offset = 3;
  for (size_t i = 0; i < model.bone_names.size(); i++)
  {
    Matrix4<T> tr = Matrix4<T>::Identity();
    const auto& rot_params = pose_params.col(i + offset);

    int mapping[] = HAND_XYZ_TO_ROTATIONAL_PARAMETERIZATION;
    tr.block(0, 0, 3, 3).noalias() = 
      (AngleAxis<T>(rot_params(mapping[2]), Vector3<T>::UnitZ()) *
        AngleAxis<T>(rot_params(mapping[1]), Vector3<T>::UnitY()) *
        AngleAxis<T>(rot_params(mapping[0]), Vector3<T>::UnitX())).matrix();
    
    relatives[i].noalias() = model.base_relatives[i].cast<T>() * tr;
  }
}

template<typename T>
void get_skinned_vertex_positions(
  const HandModelEigen& model,
  const Matrix3X<T>& pose_params,
  Matrix3X<T>* positions,
  bool apply_global = true)
{
  vector_of_Matrix4<T> relatives, absolutes, transforms;
  get_posed_relatives(model, pose_params, &relatives);
  relatives_to_absolutes(relatives, model.parents, &absolutes);
  
  // Get bone transforms.
  transforms.resize(absolutes.size());
  for (size_t i = 0; i < absolutes.size(); i++)
  {
    transforms[i].noalias() = absolutes[i] * model.inverse_base_absolutes[i].cast<T>();
  }

  // Transform vertices by necessary transforms. + apply skinning
  *positions = Matrix3X<T>::Zero(3, model.base_positions.cols());
  for (size_t i = 0; i < transforms.size(); i++)
  {
    positions->noalias() = *positions + 
      ((transforms[i] * model.base_positions.colwise().homogeneous().cast<T>()).array()
        .rowwise() * model.weights.row(i).cast<T>()).matrix()  
      .topRows(3);
  }

  if (model.is_mirrored)
    positions->row(0) = -positions->row(0);

  if (apply_global)
    apply_global_transform(pose_params, positions);
}

template<typename T>
void to_pose_params(const T* const theta,
  const std::vector<std::string>& bone_names,
  Matrix3X<T> *ppose_params)
{
  auto& pose_params = *ppose_params;
  pose_params.resize(3, bone_names.size() + 3);
  pose_params.setZero();

  pose_params.col(0) = Map<const Vector3<T>>(&theta[0]);
  pose_params.col(1).setOnes();
  pose_params.col(2) = Map<const Vector3<T>>(&theta[3]);

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

template<typename T>
void hand_objective(
  const T* const theta,
  const HandDataEigen& data,
  T *perr)
{
  Matrix3X<T> pose_params;
  to_pose_params(theta, data.model.bone_names, &pose_params);
  
  Matrix3X<T> vertex_positions;
  get_skinned_vertex_positions(data.model, pose_params, &vertex_positions);

  Map<Matrix3X<T>> err(perr, 3, data.correspondences.size());
  for (size_t i = 0; i < data.correspondences.size(); i++)
  {
    err.col(i) = data.points.col(i).cast<T>() - vertex_positions.col(data.correspondences[i]);
  }
}

template<typename T>
void hand_objective(
  const T* const theta,
  const T* const us,
  const HandDataEigen& data,
  T *perr)
{
  Matrix3X<T> pose_params;
  to_pose_params(theta, data.model.bone_names, &pose_params);

  Matrix3X<T> vertex_positions;
  get_skinned_vertex_positions(data.model, pose_params, &vertex_positions);

  Map<Matrix3X<T>> err(perr, 3, data.correspondences.size());
  for (size_t i = 0; i < data.correspondences.size(); i++)
  {
    const auto& verts = data.model.triangles[data.correspondences[i]].verts;
    const T* const u = &us[2 * i];

    Vector3<T> hand_point = u[0] * vertex_positions.col(verts[0]) + u[1] * vertex_positions.col(verts[1])
      + (1. - u[0] - u[1])*vertex_positions.col(verts[2]);
    err.col(i) = data.points.col(i).cast<T>() - hand_point;
  }
}
