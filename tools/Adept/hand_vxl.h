// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once

#include <vector>
#include <string>

#include <vnl\vnl_matrix.h>
#include <vnl\vnl_matrix_ref.h>
#include <vnl\vnl_matrix_fixed.h>
#include <vnl\vnl_matrix_fixed_ref.h>
#include <vnl\vnl_vector_fixed.h>
#include <vnl\vnl_transpose.h>

#include <adept_source.h>

#include "../matrix.h"
#include "../defs.h"
#include "utils_vxl.h"

using adept::adouble;

template<typename T>
using vnl_matrix_4 = vnl_matrix_fixed<T, 4, 4>;
template<typename T>
using vnl_matrix_3 = vnl_matrix_fixed<T, 3, 3>;

using std::vector;
using std::string;

////////////////////////////////////////////////////////////
//////////////////// Declarations //////////////////////////
////////////////////////////////////////////////////////////

template<typename T>
void apply_global_transform(
  const vnl_matrix<T>& pose_params,
  vnl_matrix<T>* positions);

template<typename T>
void get_posed_relatives(
  const HandModelVXL& model,
  const vnl_matrix<T>& pose_params,
  vector<vnl_matrix_4<T>>* prelatives);

template<typename T>
void hand_objective(
  const vector<T>& params,
  const HandDataVXL& data,
  T *perr);

////////////////////////////////////////////////////////////
//////////////////// Definitions ///////////////////////////
////////////////////////////////////////////////////////////

/*template <class S, class T>
void my_vnl_copy(S const *src, T *dst, unsigned n)
{
  for (unsigned int i = 0; i<n; ++i)
    dst[i] = T(src[i]);
}

template <class S, class T>
void my_vnl_copy(S const &src, T &dst)
{
  assert(src.size() == dst.size());
  my_vnl_copy(src.begin(), dst.begin(), src.size());
}*/

template<typename T>
void angle_axis_to_rotation_matrix(
  const vnl_vector<T> angle_axis,
  vnl_matrix_3<T> *R)
{
  T norm = sqrt(sqnorm(angle_axis.size(), &angle_axis(0)));
  if (norm < .0001)
  {
    R->set_identity();
    return;
  }

  T x = angle_axis(0) / norm;
  T y = angle_axis(1) / norm;
  T z = angle_axis(2) / norm;

  T s = sin(norm);
  T c = cos(norm);

  T data[] = { x*x + (1 - x*x)*c, x*y*(1 - c) - z*s, x*z*(1 - c) + y*s,
    x*y*(1 - c) + z*s, y*y + (1 - y*y)*c, y*z*(1 - c) - x*s,
    x*z*(1 - c) - y*s, z*y*(1 - c) + x*s, z*z + (1 - z*z)*c };
  R->set(data);
}

/*template<>
void apply_global_transform(
  const vnl_matrix<adouble>& pose_params,
  vnl_matrix<adouble>* positions)
{
  vnl_matrix_3<adouble> R;
  angle_axis_to_rotation_matrix(pose_params.get_row(0), &R);

  for (int i = 0; i < 3; i++)
    R.scale_column(i, pose_params(1, i));

  *positions *= R.transpose();
  for (unsigned int i = 0; i < positions->rows(); i++)
  {
    positions->set_row(i, positions->get_row(i) + pose_params.get_row(2));
  }
}*/

template<typename T>
void apply_global_transform(
  const vnl_matrix<T>& pose_params,
  vnl_matrix<T>* positions)
{
  vnl_matrix_3<T> R;
  angle_axis_to_rotation_matrix(pose_params.get_row(0), &R);

  for (int i = 0; i < 3; i++)
    R.scale_column(i, pose_params(1, i));

  *positions *= vnl_transpose(R);
  for (unsigned int i = 0; i < positions->rows(); i++)
  {
    positions->set_row(i, positions->get_row(i) + pose_params.get_row(2));
  }
}

template<typename T>
void relatives_to_absolutes(
  const vector<vnl_matrix_4<T>>& relatives,
  const vector<int>& parents,
  vector<vnl_matrix_4<T>>* pabsolutes)
{
  auto& absolutes = *pabsolutes;
  absolutes.resize(parents.size());
  for (size_t i = 0; i < parents.size(); i++)
  {
    if (parents[i] == -1)
      absolutes[i] = relatives[i];
    else
      absolutes[i] = absolutes[parents[i]] * relatives[i];
  }
}

template<typename T>
void euler_angles_to_rotation_matrix(
  const T* const xzy,
  vnl_matrix_3<T> *pR)
{
  T tx = xzy[0], ty = xzy[2], tz = xzy[1];
  T Rx_data[] = { 1, 0, 0, 0, cos(tx), -sin(tx), 0, sin(tx), cos(tx) };
  T Ry_data[] = { cos(ty), 0, sin(ty), 0, 1, 0, -sin(ty), 0, cos(ty) };
  T Rz_data[] = { cos(tz), -sin(tz), 0, sin(tz), cos(tz), 0, 0, 0, 1 };

  vnl_matrix_ref<T> Rx(3, 3, Rx_data), Ry(3, 3, Ry_data), Rz(3, 3, Rz_data);

  *pR = Rz * Ry * Rx;
}
/*
template<>
void get_posed_relatives(
  const HandModelVXL& model,
  const vnl_matrix<adouble>& pose_params,
  vector<vnl_matrix_4<adouble>>* prelatives)
{
  auto& relatives = *prelatives;
  relatives.resize(model.base_relatives.size());

  int offset = 3;
  for (size_t i = 0; i < model.bone_names.size(); i++)
  {
    vnl_matrix_4<adouble> tr;
    tr.set_identity();

    vnl_matrix_3<adouble> R;
    euler_angles_to_rotation_matrix(pose_params[(unsigned int)i + offset], &R);
    tr.update(R, 0, 0);

    my_vnl_copy(model.base_relatives[i], relatives[i]);
    relatives[i] *= tr;
  }
}*/

template<typename T>
void get_posed_relatives(
  const HandModelVXL& model,
  const vnl_matrix<T>& pose_params,
  vector<vnl_matrix_4<T>>* prelatives)
{
  auto& relatives = *prelatives;
  relatives.resize(model.base_relatives.size());

  int offset = 3;
  for (size_t i = 0; i < model.bone_names.size(); i++)
  {
    vnl_matrix_4<T> tr;
    tr.set_identity();

    vnl_matrix_3<T> R;
    euler_angles_to_rotation_matrix(pose_params[(unsigned int)i + offset], &R);
    tr.update(R, 0, 0);

    relatives[i] = model.base_relatives[i] * tr;
  }
}

template<typename T>
void get_skinned_vertex_positions(
  const HandModelVXL& model,
  const vnl_matrix<T>& pose_params,
  vnl_matrix<T>* positions,
  bool apply_global)
{
  vector<vnl_matrix_4<T>> relatives, absolutes, transforms;
  get_posed_relatives(model, pose_params, &relatives);
  relatives_to_absolutes(relatives, model.parents, &absolutes);

  // Get bone transforms.
  transforms.resize(absolutes.size());
  for (size_t i = 0; i < absolutes.size(); i++)
  {
    transforms[i] = absolutes[i] * model.inverse_base_absolutes[i];
  }

  // Transform vertices by necessary transforms. + apply skinning
  positions->set_size(model.base_positions.rows(), 3);
  positions->fill(0.);
  for (size_t i_bone = 0; i_bone < transforms.size(); i_bone++)
  {
    auto curr_positions = model.base_positions * vnl_transpose(transforms[i_bone].get_n_rows(0, 3));

    for (int i = 0; i < 3; i++)
      positions->set_column(i, positions->get_column(i) +
        element_product(curr_positions.get_column(i), model.weights.get_row((unsigned int)i_bone)));
  }

  if (model.is_mirrored)
    positions->scale_column(0, -1);

  if (apply_global)
    apply_global_transform(pose_params, positions);
}
/*
template<>
void get_skinned_vertex_positions(
  const HandModelVXL& model,
  const vnl_matrix<adouble>& pose_params,
  vnl_matrix<adouble>* positions,
  bool apply_global)
{
  vector<vnl_matrix_4<adouble>> relatives, absolutes, transforms;
  get_posed_relatives(model, pose_params, &relatives);
  relatives_to_absolutes(relatives, model.parents, &absolutes);

  // Get bone transforms.
  transforms.resize(absolutes.size());
  for (size_t i = 0; i < absolutes.size(); i++)
  {
    vnl_matrix_4<adouble> tmp;
    my_vnl_copy(model.inverse_base_absolutes[i], tmp);
    transforms[i] = absolutes[i] * tmp;
  }

  // adoubleransform vertices by necessary transforms. + apply skinning
  positions->set_size(model.base_positions.rows(), 3);
  positions->fill(0.);
  vnl_matrix<adouble> base_positions(model.base_positions.rows(), model.base_positions.cols()),
    weights(model.weights.rows(), model.weights.cols());
  my_vnl_copy(model.base_positions, base_positions);
  my_vnl_copy(model.weights, weights);
  for (size_t i_bone = 0; i_bone < transforms.size(); i_bone++)
  {
    auto curr_positions = base_positions * (transforms[i_bone].get_n_rows(0, 3)).transpose();

    for (int i = 0; i < 3; i++)
      positions->set_column(i, positions->get_column(i) +
        element_product(curr_positions.get_column(i), weights.get_row((unsigned int)i_bone)));
  }

  if (model.is_mirrored)
    positions->scale_column(0, -1);

  if (apply_global)
    apply_global_transform(pose_params, positions);
}*/

//% !!!!!!! fixed order pose_params !!!!!
//% 1) global_rotation 2) scale 3) global_translation
//% 4) wrist
//% 5) thumb1, 6)thumb2, 7) thumb3, 8) thumb4
//%       similarly: index, middle, ring, pinky
//%       end) forearm
template<typename T>
void to_pose_params(const T* const theta,
  const vector<string>& bone_names,
  vnl_matrix<T> *ppose_params)
{
  auto& pose_params = *ppose_params;
  pose_params.set_size((unsigned int)bone_names.size() + 3, 3);
  pose_params.fill(0.);

  pose_params.set_row(0, &theta[0]);
  pose_params.set_row(1, 1.);
  pose_params.set_row(2, &theta[3]);

  int i_theta = 6;
  int i_pose_params = 5;
  int n_fingers = 5;
  for (int i_finger = 0; i_finger < n_fingers; i_finger++)
  {
    for (int i = 2; i <= 4; i++)
    {
      pose_params(i_pose_params, 0) = theta[i_theta++];
      if (i == 2)
      {
        pose_params(i_pose_params, 1) = theta[i_theta++];
      }
      i_pose_params++;
    }
    i_pose_params++;
  }
}

template<typename T>
void hand_objective(
  const T* const params,
  const HandDataVXL& data,
  T *perr)
{
  vnl_matrix<T> pose_params;
  to_pose_params(params, data.model.bone_names, &pose_params);

  vnl_matrix<T> vertex_positions;
  get_skinned_vertex_positions(data.model, pose_params, &vertex_positions, true);


  vnl_matrix_ref<T> err((unsigned int)data.correspondences.size(), 3, perr); // vnl is row based
  for (int i = 0; i < data.correspondences.size(); i++)
  {
    for (int j = 0; j < 3; j++)
      err(i, j) = data.points(i, j) - vertex_positions(data.correspondences[i], j);
    //err.set_row(i, data.points.get_row(i) - vertex_positions.get_row(data.correspondences[i]));
  }
}
