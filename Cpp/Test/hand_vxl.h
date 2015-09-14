#pragma once

#include <vector>
#include <string>

#include <vnl\vnl_matrix.h>
#include <vnl\vnl_matrix_ref.h>
#include <vnl\vnl_matrix_fixed.h>
#include <vnl\vnl_matrix_fixed.txx>
#include <vnl\vnl_matrix_fixed_ref.h>
#include <vnl\vnl_vector.h>
#include <vnl\vnl_vector_fixed.txx>
#include <vnl\vnl_transpose.h>

#include <adept.h>

#include "../matrix.h"
#include "../defs.h"

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
void hand_objective(
  const vector<T>& params,
  const HandDataVXL& data,
  T *perr);

////////////////////////////////////////////////////////////
//////////////////// Definitions ///////////////////////////
////////////////////////////////////////////////////////////

template <class S, class T>
void my_vnl_copy(S const *src, T *dst, unsigned n)
{
  for (unsigned int i = 0; i<n; ++i)
    dst[i] = T(src[i]);
}

template <class S, class T>
void my_vnl_copy(const vnl_matrix<S>& src, vnl_matrix<T> *dst)
{
  dst->set_size(src.rows(), src.cols());
  my_vnl_copy(src.begin(), dst->begin(), src.size());
}

/*template <class S, class T>
void convert_data(const HandDataVXL<S>& src, HandDataVXL *dst)
{
  dst->correspondences = src.correspondences;
  my_vnl_copy(src.points, &dst->points);

  auto& srcm = src.model;
  auto& dsctm = dst->model;
  dsctm.bone_names = srcm.bone_names;
  dsctm.parents = srcm.parents;
  dsctm.is_mirrored = srcm.is_mirrored;
  my_vnl_copy(srcm.base_positions, &dsctm.base_positions);
  my_vnl_copy(srcm.weights, &dsctm.weights);

  dsctm.base_relatives.resize(srcm.base_relatives.size());
  dsctm.inverse_base_absolutes.resize(srcm.inverse_base_absolutes.size());
  for (size_t i = 0; i < srcm.base_relatives.size(); i++)
  {
    //my_vnl_copy(srcm.base_relatives.begin(), dsctm.base_relatives.begin(), 
    //  srcm.base_relatives.size());
    //my_vnl_copy(srcm.inverse_base_absolutes.begin(), dsctm.inverse_base_absolutes.begin(), 
    //  srcm.inverse_base_absolutes.size());
  }
}*/

template<typename T>
void angle_axis_to_rotation_matrix(
  const vnl_vector<T> angle_axis,
  vnl_matrix<T> *R)
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

template<typename T>
void apply_global_transform(
  const vnl_matrix<T>& pose_params, 
  vnl_matrix<T>* positions)
{
  vnl_matrix<T> R(3, 3);
  angle_axis_to_rotation_matrix(pose_params.get_row(0), &R);
  
  for (int i = 0; i < 3; i++)
    R.scale_column(i, pose_params(1, i));
  
  *positions *= R.transpose();
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
  //const T* const xzy,
  const vnl_vector<T>& xzy,
  vnl_matrix_3<T> *pR)
{
  //T tx = xzy[0], ty = xzy[2], tz = xzy[1];
  T tx = xzy(0), ty = xzy(2), tz = xzy(1);
  vnl_matrix_3<T> Rx, Ry, Rz;
  Rx.set_identity();
  Rx(1, 1) = cos(tx);
  Rx(2, 1) = sin(tx);
  Rx(1, 2) = -Rx(2, 1);
  Rx(2, 2) = Rx(1, 1);

  Ry.set_identity();
  Ry(0, 0) = cos(ty);
  Ry(0, 2) = sin(ty);
  Ry(2, 0) = -Ry(0, 2);
  Ry(2, 2) = Ry(0, 0);

  Rz.set_identity();
  Rz(0, 0) = cos(tz);
  Rz(1, 0) = sin(tz);
  Rz(0, 1) = -Rz(1, 0);
  Rz(1, 1) = Rz(0, 0);

  *pR = Rz * Ry * Rx;
}

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
    //euler_angles_to_rotation_matrix(pose_params.get_row(8 + offset), &R);
    euler_angles_to_rotation_matrix(pose_params.get_row((unsigned int)(i + offset)), &R);
    //euler_angles_to_rotation_matrix(pose_params[(unsigned int)(i + offset)], &R);
    //R(0, 0) = pose_params(5, 0);
    for (int ii = 0; ii < 3; ii++) // my tr.update
      for (int ij = 0; ij < 3; ij++)
        tr(ii, ij) = R(ii, ij);
    relatives[i] = model.base_relatives[i] * tr;
  }
}

template<typename T>
void get_skinned_vertex_positions(
  const HandModelVXL& model,
  const vnl_matrix<T>& pose_params,
  vnl_matrix<T>* ppositions,
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
  auto& positions = *ppositions;
  // fill 0 (function fill did not work with adept)
  my_fill(positions, 0.);
transforms.clear();
transforms.resize(absolutes.size());
  for (size_t i_bone = 0; i_bone < transforms.size(); i_bone++)
  {
    transforms[i_bone].set_identity();
    transforms[i_bone](0,0) = pose_params(i_bone+3,0);
  }
  for (size_t i_bone = 0; i_bone < transforms.size(); i_bone++)
  {
    //transforms[i_bone].set_identity();
    //transforms[i_bone](0,0) = pose_params(i_bone+3,0);
    vnl_matrix<T> curr_positions(model.base_positions.rows(), 4);
    my_ordinary_mat_mult(model.base_positions, transforms[i_bone].transpose(), curr_positions);
    for (unsigned int i_vert = 0; i_vert < positions.rows(); i_vert++)
      for (int i = 0; i < 3; i++)
        positions(i_vert, i) = positions(i_vert, i) +
        curr_positions(i_vert, i) * model.weights((unsigned int)i_bone, i_vert);
  }

  if (model.is_mirrored)
    positions.scale_column(0, -1);
  
  if (apply_global)
    apply_global_transform(pose_params, &positions);
}

// fill 0 (function fill did not work with adept)
template<class M, typename T>
void my_fill(M& x, const T& val)
{
  for (unsigned int i = 0; i < x.rows(); i++)
    for (unsigned int j = 0; j < x.cols(); j++)
      x(i, j) = val;
}

//% !!!!!!! fixed order pose_params !!!!!
//% 1) global_rotation 2) scale 3) global_translation
//% 4) wrist
//% 5) thumb1, 6)thumb2, 7) thumb3, 8) thumb4
//%       similarly: index, middle, ring, pinky
//%       end) forearm
template<typename T>
void to_pose_params(const vector<T>& theta,
  const vector<string>& bone_names,
  vnl_matrix<T> *ppose_params)
{
  auto& pose_params = *ppose_params;
  //pose_params.set_size();
  my_fill(pose_params, 0.);

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
  const vector<T>& params, 
  const HandDataVXL& data,
  T *err)
{
  vnl_matrix<T> pose_params((unsigned int)data.model.bone_names.size() + 3, 3);
  to_pose_params(params, data.model.bone_names, &pose_params);

  vnl_matrix<T> vertex_positions(data.model.base_positions.rows(), 3);
  get_skinned_vertex_positions(data.model, pose_params, &vertex_positions, true);

  for (int i = 0; i < data.correspondences.size(); i++)
  {
    for (int j = 0; j < 3; j++)
    {
      err[i*3 + j] = data.points(i, j) - vertex_positions(data.correspondences[i], j);
    }
  }
}