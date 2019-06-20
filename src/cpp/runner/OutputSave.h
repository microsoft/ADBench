#pragma once

#include <string>
#include <vector>
#include "../shared/utils.h"

void save_time_to_file(const std::string& filepath, const double objective_time, const double derivative_time);

void save_objective_to_file(const std::string& filepath, const double& value);

void save_gradient_to_file(const std::string& filepath, const std::vector<double>& gradient);

void save_errors_to_file(const std::string& filepath, const std::vector<double>& reprojection_error,
                         const std::vector<double>& zach_weight_error);

void save_sparse_j_to_file(const std::string& filepath, const BASparseMat& jacobian);
