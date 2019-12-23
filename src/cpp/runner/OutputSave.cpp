// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#include "OutputSave.h"

#include <fstream>

std::string objective_file_name(const std::string& output_prefix, const std::string& input_basename,
                                const std::string& module_basename)
{
    return output_prefix + input_basename + "_F_" + module_basename + ".txt";
}

std::string jacobian_file_name(const std::string& output_prefix, const std::string& input_basename,
                               const std::string& module_basename)
{
    return output_prefix + input_basename + "_J_" + module_basename + ".txt";
}

void save_time_to_file(const std::string& filepath, const double objective_time, const double derivative_time)
{
    std::ofstream out(filepath);

    out << std::scientific << objective_time << std::endl << derivative_time << std::endl;
    out.close();
}

void save_value_to_file(const std::string& filepath, const double& value)
{
    precise_ofstream<std::remove_reference_t<decltype(value)>> out(filepath);

    out << value << std::endl;
    out.close();
}

void save_vector_to_file(const std::string& filepath, const std::vector<double>& gradient)
{
    precise_ofstream<std::remove_reference_t<decltype(gradient)>::value_type> out(filepath);

    for (const auto& i : gradient)
    {
        out << i << std::endl;
    }

    out.close();
}

void save_errors_to_file(const std::string& filepath, const std::vector<double>& reprojection_error,
                         const std::vector<double>& zach_weight_error)
{
    precise_ofstream<std::remove_reference_t<decltype(reprojection_error)>::value_type> out(filepath);

    out << "Reprojection error:" << std::endl;
    for (const auto& i : reprojection_error)
    {
        out << i << std::endl;
    }

    out << "Zach weight error:" << std::endl;
    for (const auto& i : zach_weight_error)
    {
        out << i << std::endl;
    }

    out.close();
}

void save_jacobian_to_file(const std::string& filepath, int jacobian_ncols, int jacobian_nrows, const std::vector<double>& jacobian)
{
    const auto passed_size = static_cast<decltype(jacobian.size())>(jacobian_ncols) * jacobian_nrows;
    if (jacobian.size() != passed_size)
    {
        throw std::logic_error("The actual passed jacobian size is inconsistent with the passed number of rows and columns.");
    }

    std::ofstream out(filepath);

    auto max_digits = std::numeric_limits<double>::max_digits10;
    out.precision(max_digits);
    out << std::scientific;

    for (auto i = 0; i < jacobian_nrows; i++)
    {
        out << jacobian[i];

        for (auto j = 1; j < jacobian_ncols; j++)
        {
            out << "\t"  << jacobian[jacobian_nrows * j + i];
        }
        out << std::endl;
    }

    out.close();
}

void save_sparse_j_to_file(const std::string& filepath, const BASparseMat& jacobian)
{
    write_J_sparse(filepath, jacobian);
}
