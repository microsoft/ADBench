// ManualHand.cpp : Defines the exported functions for the DLL.
#include "ManualHand.h"

#include "../../shared/hand_light_matrix.h";
#include "hand_d.h";

// This function must be called before any other function.
void ManualHand::prepare(HandInput&& input)
{
    _input = input;
    _complicated = _input.us.size() != 0;
    auto err_size = 3 * _input.data.correspondences.size();
    _output = { std::vector<double>(err_size), std::vector<double>(err_size * ((_complicated ? 2 : 0) + _input.theta.size())) };
}

HandOutput ManualHand::output()
{
    return _output;
}

// TODO: check whether the loop gets optimized away
void ManualHand::calculateObjective(int times)
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

void ManualHand::calculateJacobian(int times)
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
    return new ManualHand();
}
