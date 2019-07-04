#pragma once

#include <vector>
#include <unordered_map>
#include <string>

#include <Eigen/Dense>
#include <Eigen/StdVector>

#include "../../shared/defs.h"
#include "../../shared/utils.h"
#include "../../shared/hand_eigen_model.h"

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
    Matrix3d* R,
    vector<Matrix3d>* pdR);

void apply_global_transform_d(
    const vector<int>& corresp,
    const Matrix3Xd& pose_params,
    Matrix3Xd* ppositions,
    double* pJ,
    Matrix3d* pR);

void apply_global_transform_d(
    const double* const us,
    const vector<Triangle>& triangles,
    const vector<int>& corresp,
    const Matrix3Xd& pose_params,
    Matrix3Xd* ppositions,
    double* pJ,
    Matrix3d* pR);

void relatives_to_absolutes_d(
    const avector<Matrix4d>& relatives,
    const avector<Matrix4d>& relatives_d,
    const vector<int>& parents,
    avector<Matrix4d>* pabsolutes,
    vector<avector<Matrix4d>>* pabsolutes_d);

void euler_angles_to_rotation_matrix(
    const Vector3d& xzy,
    Matrix3d* pR,
    Matrix3d* pdR0 = nullptr,
    Matrix3d* pdR1 = nullptr);

void get_posed_relatives_d(
    const HandModelEigen& model,
    const Matrix3Xd& pose_params,
    avector<Matrix4d>* prelatives,
    avector<Matrix4d>* prelatives_d);

void get_skinned_vertex_positions_d_common(
    const HandModelEigen& model,
    const Matrix3Xd& pose_params,
    const vector<int>& corresp,
    Matrix3Xd* positions,
    vector<Matrix3Xd>* positions_d,
    double* pJ,
    bool apply_global = true);

void get_skinned_vertex_positions_d(
    const HandModelEigen& model,
    const Matrix3Xd& pose_params,
    const vector<int>& corresp,
    Matrix3Xd* positions,
    double* pJ,
    bool apply_global = true);

void get_skinned_vertex_positions_d(
    const double* const us,
    const HandModelEigen& model,
    const Matrix3Xd& pose_params,
    const vector<int>& corresp,
    Matrix3Xd* positions,
    double* pJ,
    bool apply_global = true);

void to_pose_params_d(const double* const theta,
    const vector<string>& bone_names,
    Matrix3Xd* ppose_params);

void hand_objective_d(
    const double* const theta,
    const HandDataEigen& data,
    double* perr,
    double* pJ);

void hand_objective_d(
    const double* const theta,
    const double* const us,
    const HandDataEigen& data,
    double* perr,
    double* pJ);