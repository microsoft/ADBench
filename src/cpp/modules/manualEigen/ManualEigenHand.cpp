// ManualEigenHand.cpp : Defines the exported functions for the DLL.
#include "ManualEigenHand.h"
#include "../../shared/hand_eigen.h"
#include "hand_eigen_d.h"

#include <iostream>
#include <memory>

// This function must be called before any other function.
void ManualEigenHand::prepare(HandInput&& input)
{
    copy_HandInput_to_HandEigenInput(input, _input);

    _complicated = _input.us.size() != 0;
    int err_size = 3 * _input.data.correspondences.size();
    int ncols = (_complicated ? 2 : 0) + _input.theta.size();
    _output = { std::vector<double>(err_size), ncols, err_size, std::vector<double>(err_size * ncols) };
}

HandOutput ManualEigenHand::output()
{
    return _output;
}

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
