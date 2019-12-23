// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// FiniteHand.cpp : Defines the exported functions for the DLL.
#include "FiniteHand.h"

#include "../../shared/hand_light_matrix.h"
#include "finite.h"

// This function must be called before any other function.
void FiniteHand::prepare(HandInput&& input)
{
    this->input = input;
    complicated = this->input.us.size() != 0;
    int err_size = 3 * this->input.data.correspondences.size();
    int ncols = (complicated ? 2 : 0) + this->input.theta.size();
    result = { std::vector<double>(err_size), ncols, err_size, std::vector<double>(err_size * ncols) };
    engine.set_max_output_size(err_size);
    if (complicated)
        jacobian_by_us = std::vector<double>(2 * err_size);
}

HandOutput FiniteHand::output()
{
    return result;
}

void FiniteHand::calculate_objective(int times)
{
    if (complicated)
    {
        for (int i = 0; i < times; ++i) {
            hand_objective(input.theta.data(), input.us.data(), input.data, result.objective.data());
        }
    }
    else
    {
        for (int i = 0; i < times; ++i) {
            hand_objective(input.theta.data(), input.data, result.objective.data());
        }
    }
}

void FiniteHand::calculate_jacobian(int times)
{
    if (complicated)
    {
        for (int i = 0; i < times; ++i) {
            engine.finite_differences([&](double* theta_in, double* err) {
                hand_objective(theta_in, input.us.data(), input.data, err);
                }, input.theta.data(), input.theta.size(), result.objective.size(), &result.jacobian.data()[6 * input.data.correspondences.size()]);

            for (int j = 0; j < input.us.size() / 2; ++j) {
                engine.finite_differences([&](double* us_in, double* err) {
                    // us_in points into the middle of _input.us.data()
                    hand_objective(input.theta.data(), input.us.data(), input.data, err);
                    }, &input.us.data()[j * 2], 2, result.objective.size(), jacobian_by_us.data());

                for (int k = 0; k < 3; ++k) {
                    result.jacobian[j * 3 + k] = jacobian_by_us[j * 3 + k];
                    result.jacobian[j * 3 + k + result.objective.size()] = jacobian_by_us[j * 3 + k + result.objective.size()];
                }
            }
        }
    }
    else
    {
        for (int i = 0; i < times; ++i) {
            engine.finite_differences([&](double* theta_in, double* err) {
                hand_objective(theta_in, input.data, err);
                }, input.theta.data(), input.theta.size(), result.objective.size(), result.jacobian.data());
        }
    }
}

extern "C" DLL_PUBLIC ITest<HandInput, HandOutput>* get_hand_test()
{
    return new FiniteHand();
}
