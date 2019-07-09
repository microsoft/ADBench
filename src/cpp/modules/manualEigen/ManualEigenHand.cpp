// ManualEigenHand.cpp : Defines the exported functions for the DLL.
#include "ManualEigenHand.h"
#include "../../shared/hand_eigen.h"
#include "hand_eigen_d.h"

#include <iostream>
#include <memory>

auto convert_matrix(LightMatrix<double>& lightmatrix)
{
    return Map<MatrixXd>(lightmatrix.data_, lightmatrix.nrows_, lightmatrix.ncols_);
};

// This function must be called before any other function.
void ManualEigenHand::prepare(HandInput&& input)
{
    _input.theta = input.theta;
    _input.us = input.us;
    _input.data.correspondences = input.data.correspondences;
    _input.data.model.bone_names = input.data.model.bone_names;
    _input.data.model.parents = input.data.model.parents;
    _input.data.model.triangles = input.data.model.triangles;
    _input.data.model.is_mirrored = input.data.model.is_mirrored;

    // Matrix& operator=(const DenseBase<OtherDerived>& other)
    // Copies the value of the expression other into *this with automatic resizing.
    _input.data.points = convert_matrix(input.data.points);
    int n_vertices = input.data.model.base_positions.cols();
    _input.data.model.base_positions.resize(3, n_vertices);
    for (int i = 0; i < 3; i++)
    {
        for (int j = 0; j < n_vertices; j++)
        {
            _input.data.model.base_positions(i, j) = input.data.model.base_positions(i, j);
        }
    }
    _input.data.model.weights = convert_matrix(input.data.model.weights);

    for (int i = 0; i < input.data.model.base_relatives.size(); i++)
    {
        _input.data.model.base_relatives.push_back(convert_matrix(input.data.model.base_relatives[i]));
    }
    for (int i = 0; i < input.data.model.inverse_base_absolutes.size(); i++)
    {
        _input.data.model.inverse_base_absolutes.push_back(convert_matrix(input.data.model.inverse_base_absolutes[i]));
    }

    _complicated = _input.us.size() != 0;
    int err_size = 3 * _input.data.correspondences.size();
    int ncols = (_complicated ? 2 : 0) + _input.theta.size();
    _output = { std::vector<double>(err_size), ncols, err_size, std::vector<double>(err_size * ncols) };
}

HandOutput ManualEigenHand::output()
{
    return _output;
}

// TODO: check whether the loop gets optimized away
void ManualEigenHand::calculateObjective(int times)
{
    if (_complicated)
    {
        for (int i = 0; i < times; ++i) {
            hand_objective(_input.theta.data(), _input.us.data(), _input.data, _output.objective.data());
        }
    }
    else
    {
        for (int i = 0; i < times; ++i) {
            hand_objective(_input.theta.data(), _input.data, _output.objective.data());
        }
    }
}

void ManualEigenHand::calculateJacobian(int times)
{
    if (_complicated)
    {
        for (int i = 0; i < times; ++i) {
            hand_objective_d(_input.theta.data(), _input.us.data(), _input.data, _output.objective.data(), _output.jacobian.data());
        }
    }
    else
    {
        for (int i = 0; i < times; ++i) {
            hand_objective_d(_input.theta.data(), _input.data, _output.objective.data(), _output.jacobian.data());
        }
    }
}

extern "C" DLL_PUBLIC ITest<HandInput, HandOutput>* GetHandTest()
{
    return new ManualEigenHand();
}
