#include "OutputSave.h"

#include <fstream>

void save_time_to_file(const std::string& filepath, const double objective_time, const double derivative_time)
{
    std::ofstream out(filepath);
    out << std::scientific << objective_time << std::endl << derivative_time;
    out.close();
}

void save_objective_to_file(const std::string& filepath, const double& value)
{
    std::ofstream out(filepath);
    out << std::scientific << value;
    out.close();
}

void save_gradient_to_file(const std::string& filepath, const std::vector<double>& gradient)
{
    std::ofstream out(filepath);

    for (const auto& i : gradient)
    {
        out << std::scientific << i << std::endl;
    }

    out.close();
}

void save_errors_to_file(const std::string& filepath, const std::vector<double>& reprojection_error,
                         const std::vector<double>& zach_weight_error)
{
    std::ofstream out(filepath);

    out << "Reprojection error:" << std::endl;
    for (const auto& i : reprojection_error)
    {
        out << std::scientific << i << std::endl;
    }

    out << "Zach weight error:" << std::endl;
    for (const auto& i : zach_weight_error)
    {
        out << std::scientific << i << std::endl;
    }

    out.close();
}

void save_sparse_j_to_file(const std::string& filepath, const BASparseMat& jacobian)
{
    write_J_sparse(filepath, jacobian);
}
