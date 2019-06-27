#pragma once

#include <array>
#include <vector>
#include <string>

#include "../../shared/defs.h"
#include "../../shared/light_matrix.h"
#include "../../shared/utils.h"

//const Vector3d& angle_axis,
//Matrix3d* R,
//vector<Matrix3d>* pdR
void angle_axis_to_rotation_matrix_d(
    const double const* angle_axis,
    LightMatrix<double>& R,
    std::array<LightMatrix<double>, 3>& dR);

//const vector<int>& corresp,
//const Matrix3Xd& pose_params,
//Matrix3Xd* ppositions,
//double* pJ,
//Matrix3d* pR
void apply_global_transform_d(
    const std::vector<int>& corresp,
    const LightMatrix<double>& pose_params,
    LightMatrix<double>& positions,
    double* pJ,
    LightMatrix<double>& R);

//const double* const us,
//const vector<Triangle>& triangles,
//const vector<int>& corresp,
//const Matrix3Xd& pose_params,
//Matrix3Xd* ppositions,
//double* pJ,
//Matrix3d* pR
void apply_global_transform_d(
    const double* const us,
    const std::vector<Triangle>& triangles,
    const std::vector<int>& corresp,
    const LightMatrix<double>& pose_params,
    LightMatrix<double>& positions,
    double* pJ,
    LightMatrix<double>& R);

//using avector = std::vector<T, Eigen::aligned_allocator<T>>;
//const avector<Matrix4d>& relatives,
//const avector<Matrix4d>& relatives_d,
//const vector<int>& parents,
//avector<Matrix4d>* pabsolutes,
//vector<avector<Matrix4d>>* pabsolutes_d
void relatives_to_absolutes_d(
    const std::vector<LightMatrix<double>>& relatives,
    const std::vector<LightMatrix<double>>& relatives_d,
    const std::vector<int>& parents,
    std::vector<LightMatrix<double>>& absolutes,
    std::vector<std::vector<LightMatrix<double>>>& absolutes_d);

//const Vector3d& xzy,
//Matrix3d* pR,
//Matrix3d* pdR0 = nullptr,
//Matrix3d* pdR1 = nullptr
void euler_angles_to_rotation_matrix(
    const double const* xzy,
    LightMatrix<double>& R,
    LightMatrix<double>* pdR0 = nullptr,
    LightMatrix<double>* pdR1 = nullptr);

//const HandModelEigen& model,
//const Matrix3Xd& pose_params,
//avector<Matrix4d>* prelatives,
//avector<Matrix4d>* prelatives_d
void get_posed_relatives_d(
    const HandModelLightMatrix& model,
    const LightMatrix<double>& pose_params,
    std::vector<LightMatrix<double>>& relatives,
    std::vector<LightMatrix<double>>& relatives_d);

//const HandModelEigen& model,
//const Matrix3Xd& pose_params,
//const vector<int>& corresp,
//Matrix3Xd* positions,
//vector<Matrix3Xd>* positions_d,
//double* pJ,
//bool apply_global = true
void get_skinned_vertex_positions_d_common(
    const HandModelLightMatrix& model,
    const LightMatrix<double>& pose_params,
    const std::vector<int>& corresp,
    LightMatrix<double>& positions,
    std::vector<LightMatrix<double>>& positions_d,
    double* pJ,
    bool apply_global = true);

//const HandModelEigen& model,
//const Matrix3Xd& pose_params,
//const vector<int>& corresp,
//Matrix3Xd* positions,
//double* pJ,
//bool apply_global = true
void get_skinned_vertex_positions_d(
    const HandModelLightMatrix& model,
    const LightMatrix<double>& pose_params,
    const std::vector<int>& corresp,
    LightMatrix<double>& positions,
    double* pJ,
    bool apply_global = true);

//const double* const us,
//const HandModelEigen& model,
//const Matrix3Xd& pose_params,
//const vector<int>& corresp,
//Matrix3Xd* positions,
//double* pJ,
//bool apply_global = true
void get_skinned_vertex_positions_d(
    const double* const us,
    const HandModelLightMatrix& model,
    const LightMatrix<double>& pose_params,
    const std::vector<int>& corresp,
    LightMatrix<double>& positions,
    double* pJ,
    bool apply_global = true);

//const double* const theta,
//const vector<string>& bone_names,
//Matrix3Xd* ppose_params
void to_pose_params_d(
    const double* const theta,
    const std::vector<std::string>& bone_names,
    LightMatrix<double>& pose_params);

//const double* const theta,
//const HandDataEigen& data,
//double* perr,
//double* pJ
void hand_objective_d(
    const double* const theta,
    const HandDataLightMatrix& data,
    double* perr,
    double* pJ);

//const double* const theta,
//const double* const us,
//const HandDataEigen& data,
//double* perr,
//double* pJ
void hand_objective_d(
    const double* const theta,
    const double* const us,
    const HandDataLightMatrix& data,
    double* perr,
    double* pJ);
