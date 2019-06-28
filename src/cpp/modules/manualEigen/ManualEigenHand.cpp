// ManualEigenHand.cpp : Defines the exported functions for the DLL.
#include "ManualEigenHand.h"
#include "../../shared/hand_eigen.h"
#include "hand_eigen_d.h"

#include <iostream>
#include <memory>

// This function must be called before any other function.
void ManualEigenHand::prepare(HandInput&& input)
{
    auto convert_matrix = [](LightMatrix<double> lightmatrix)
    {
        MatrixXd matrix(lightmatrix.nrows_, lightmatrix.ncols_);
        for (int i = 0; i < lightmatrix.nrows_; i++)
        {
            for (int j = 0; j < lightmatrix.ncols_; j++)
            {
                matrix(i, j) = lightmatrix.data_[lightmatrix.ncols_ * i + j];
            }
        }
        Map<MatrixXd> map(matrix.data(), lightmatrix.nrows_, lightmatrix.ncols_);
        return map;
    };
    _input.theta = input.theta;
    _input.us = input.us;
    _input.data.correspondences = input.data.correspondences;
    _input.data.model.bone_names = input.data.model.bone_names;
    _input.data.model.parents = input.data.model.parents;
    _input.data.model.triangles = input.data.model.triangles;
    _input.data.model.is_mirrored = input.data.model.is_mirrored;

    _input.data.points = convert_matrix(input.data.points);
    input.data.model.base_positions.resize(_input.data.model.base_positions.rows(),
        input.data.model.base_positions.size() / _input.data.model.base_positions.rows());
    //TODO: check why input data for hand & eigen_hand have different format
    _input.data.model.base_positions = convert_matrix(input.data.model.base_positions);
    _input.data.model.weights = convert_matrix(input.data.model.weights);

    for (int i = 0; i < input.data.model.base_relatives.size(); i++)
    {
        _input.data.model.base_relatives.push_back(convert_matrix(input.data.model.base_relatives[i]));
    }
    for (int i = 0; i < input.data.model.inverse_base_absolutes.size(); i++)
    {
        _input.data.model.inverse_base_absolutes.push_back(convert_matrix(input.data.model.inverse_base_absolutes[i]));
    }

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

extern "C" __declspec(dllexport) ITest<HandInput, HandOutput>* __cdecl GetHandTest()
{
    return new ManualEigenHand();
}
