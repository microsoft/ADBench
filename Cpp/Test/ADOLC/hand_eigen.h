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
  const unordered_map<string, Vector3<T>>& pose_params, 
  Matrix3X<T>* positions)
{
  Matrix3<T> R;
  angle_axis_to_rotation_matrix(pose_params.at("global_rotation"), &R);
  R.noalias() = (R.array().rowwise() * pose_params.at("scale").transpose().array()).matrix();
  
  *positions = (R * (*positions)).colwise() + pose_params.at("global_translation");
}

template<typename T>
void relatives_to_absolutes(
  const vector<Matrix4<T>>& relatives,
  const vector<int>& parents,
  vector<Matrix4<T>>* pabsolutes)
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
  const HandModel& model,
  const unordered_map<string, Vector3<T>>& pose_params,
  vector<Matrix4<T>>* prelatives)
{
  auto& relatives = *prelatives;
  relatives.resize(model.base_relatives.size());

  for (size_t i = 0; i < model.bone_names.size(); i++)
  {
    Matrix4<T> tr = Matrix4<T>::Identity();
    const Vector3<T>& rot_params = pose_params.at(model.bone_names[i]);

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
  const HandModel& model,
  const unordered_map<string, Vector3<T>>& pose_params,
  Matrix3X<T>* positions,
  bool apply_global = true)
{
  vector<Matrix4<T>> relatives, absolutes, transforms;
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
void to_pose_params(const vector<T>& theta,
  const vector<string>& bone_names,
  unordered_map<string, Vector3<T>> *ppose_params)
{
  auto& pose_params = *ppose_params;
  pose_params.reserve(bone_names.size() + 3);

  pose_params["global_rotation"] = Map<const Vector3<T>>(&theta[0]);
  pose_params["scale"] = Vector3<T>::Ones();
  pose_params["global_translation"] = Map<const Vector3<T>>(&theta[3]);

  for (const auto& bone_name : bone_names)
    pose_params[bone_name] = Vector3<T>::Zero();

  int i_theta = 6;
  string fingers[] = { "thumb", "index", "middle", "ring", "pinky" };
  for (const auto& finger : fingers)
  {
    for (int i = 2; i <= 4; i++)
    {
      string bone_name = finger + std::to_string(i);
      auto& curr = pose_params[bone_name];
      curr(0) = theta[i_theta];
      i_theta = i_theta + 1;
      if (i == 2)
      {
        curr(1) = theta[i_theta];
        i_theta = i_theta + 1;
      }
    }
  }
}

template<typename T>
void hand_objective(
  const vector<T>& params, 
  const HandData& data,
  T *perr)
{
  unordered_map<string,Vector3<T>> pose_params;
  to_pose_params(params, data.model.bone_names, &pose_params);
  
  Matrix3X<T> vertex_positions;
  get_skinned_vertex_positions(data.model, pose_params, &vertex_positions);

  Map<Matrix3X<T>> err(perr, 3, data.correspondences.size());
  for (int i = 0; i < data.correspondences.size(); i++)
  {
    err.col(i) = data.points.col(i).cast<T>() - vertex_positions.col(data.correspondences[i]);
  }
}