// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once

#include <string>
#include <vector>
#include "../shared/utils.h"

std::string objective_file_name(const std::string& output_prefix, const std::string& input_basename,
                                const std::string& module_basename);

std::string jacobian_file_name(const std::string& output_prefix, const std::string& input_basename,
                               const std::string& module_basename);

void save_time_to_file(const std::string& filepath, const double objective_time, const double derivative_time);

void save_value_to_file(const std::string& filepath, const double& value);

void save_vector_to_file(const std::string& filepath, const std::vector<double>& gradient);

void save_errors_to_file(const std::string& filepath, const std::vector<double>& reprojection_error,
                         const std::vector<double>& zach_weight_error);

void save_jacobian_to_file(const std::string& filepath, int jacobian_ncols, int jacobian_nrows, const std::vector<double>& jacobian);

void save_sparse_j_to_file(const std::string& filepath, const BASparseMat& jacobian);
