// FiniteHand.cpp : Defines the exported functions for the DLL.
#include "FiniteHand.h"

#include "../../shared/hand_light_matrix.h"
#include "finite.h"

// This function must be called before any other function.
void FiniteHand::prepare(HandInput&& input)
{
    _input = input;
    _complicated = _input.us.size() != 0;
    int err_size = 3 * _input.data.correspondences.size();
    int ncols = (_complicated ? 2 : 0) + _input.theta.size();
    _output = { std::vector<double>(err_size), ncols, err_size, std::vector<double>(err_size * ncols) };
    engine.set_max_output_size(err_size);
    if (_complicated)
        jacobian_by_us = std::vector<double>(2 * err_size);
}

HandOutput FiniteHand::output()
{
    return _output;
}

void FiniteHand::calculateObjective(int times)
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

void FiniteHand::calculateJacobian(int times)
{
    if (_complicated)
    {
        for (int i = 0; i < times; ++i) {
            engine.finite_differences([&](double* theta_in, double* err) {
                hand_objective(theta_in, _input.us.data(), _input.data, err);
                }, _input.theta.data(), _input.theta.size(), _output.objective.data(), _output.objective.size(), &_output.jacobian.data()[6 * _input.data.correspondences.size()]);

            for (int j = 0; j < _input.us.size() / 2; ++j) {
                engine.finite_differences_continue([&](double* us_in, double* err) {
                    // us_in points into the middle of _input.us.data()
                    hand_objective(_input.theta.data(), _input.us.data(), _input.data, err);
                    }, &_input.us.data()[j * 2], 2, _output.objective.data(), _output.objective.size(), jacobian_by_us.data());

                for (int k = 0; k < 3; ++k) {
                    _output.jacobian[j * 3 + k] = jacobian_by_us[j * 3 + k];
                    _output.jacobian[j * 3 + k + _output.objective.size()] = jacobian_by_us[j * 3 + k + _output.objective.size()];
                }
            }
        }
    }
    else
    {
        for (int i = 0; i < times; ++i) {
            engine.finite_differences([&](double* theta_in, double* err) {
                hand_objective(theta_in, _input.data, err);
                }, _input.theta.data(), _input.theta.size(), _output.objective.data(), _output.objective.size(), _output.jacobian.data());
        }
    }
}

extern "C" DLL_PUBLIC ITest<HandInput, HandOutput>* GetHandTest()
{
    return new FiniteHand();
}
