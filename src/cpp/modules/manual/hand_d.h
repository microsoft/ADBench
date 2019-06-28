#pragma once

/*
 * Manual differentiation of the hand tracking problem.
 * Adapted from the Eigen-based version.
 *
 * Functions in this file do not perform any checks on input parameters
 * for the sake of better performance.
*/

#include <array>
#include <vector>
#include <string>

#include "../../shared/defs.h"
#include "../../shared/light_matrix.h"
#include "../../shared/utils.h"

// Inputs:
// angle_axis - double[3]
// Outputs:
// R - preallocated 3x3 matrix
// dR - array of 3 preallocated 3x3 matrices
void angle_axis_to_rotation_matrix_d(
    const double const* angle_axis,
    LightMatrix<double>& R,
    std::array<LightMatrix<double>, 3>& dR);

void apply_global_transform_d_common(const LightMatrix<double>& pose_params, LightMatrix<double>& R, std::array<LightMatrix<double>, 3Ui64> & dR);

void apply_global_translation(const size_t& npts, const LightMatrix<double>& R, const LightMatrix<double>& pose_params, LightMatrix<double>& positions, double* pJ);

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
    LightMatrix<double>& R);

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
    LightMatrix<double>& R);

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
    std::vector<std::vector<LightMatrix<double>>>& absolutes_d);

// Inputs:
// xzy - double[3]
// Outputs:
// R - 3x3 matrix, allocated in this function
// pdR0 - nullable pointer to 3x3 matrix (computed only if not null)
// pdR1 - nullable pointer to 3x3 matrix (computed only if not null)
void euler_angles_to_rotation_matrix(
    const double const* xzy,
    LightMatrix<double>& R,
    LightMatrix<double>* pdR0 = nullptr,
    LightMatrix<double>* pdR1 = nullptr);

// Inputs:
// model - HandModelEigen
// pose_params - 3xN matrix
// relatives - vector of 4x4 matrices, allocated in this function
// relatives_d - vector of 4x4 matrices, allocated in this function
void get_posed_relatives_d(
    const HandModelLightMatrix& model,
    const LightMatrix<double>& pose_params,
    std::vector<LightMatrix<double>>& relatives,
    std::vector<LightMatrix<double>>& relatives_d);

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
    double* pJ);

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
    bool apply_global = true);

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
    bool apply_global = true);

// Inputs:
// theta - double[]
// bone_names - vector<string>
// Outputs:
// pose_params - 3xN matrix, allocated in this function
void to_pose_params_d(
    const double* const theta,
    const std::vector<std::string>& bone_names,
    LightMatrix<double>& pose_params);

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
    double* pJ);

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
    double* pJ);
