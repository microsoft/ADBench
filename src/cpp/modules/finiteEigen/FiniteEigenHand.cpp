// FiniteEigenHand.cpp : Defines the exported functions for the DLL.
#include "FiniteEigenHand.h"

#include "../../shared/hand_eigen.h"
#include "../finite/finite.h"

// This function must be called before any other function.
void FiniteEigenHand::prepare(HandInput&& input)
{
    copy_HandInput_to_HandEigenInput(input, this->input);

    complicated = this->input.us.size() != 0;
    int err_size = 3 * this->input.data.correspondences.size();
    int ncols = (complicated ? 2 : 0) + this->input.theta.size();
    result = { std::vector<double>(err_size), ncols, err_size, std::vector<double>(err_size * ncols) };
    engine.set_max_output_size(err_size);
    if (complicated)
        jacobian_by_us = std::vector<double>(2 * err_size);
}

HandOutput FiniteEigenHand::output()
{
    return result;
}

void FiniteEigenHand::calculateObjective(int times)
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

void FiniteEigenHand::calculateJacobian(int times)
{
    if (complicated)
    {
        for (int i = 0; i < times; ++i) {
            engine.finite_differences([&](double* theta_in, double* err) {
                hand_objective(theta_in, input.us.data(), input.data, err);
                }, input.theta.data(), input.theta.size(), result.objective.data(), result.objective.size(), &result.jacobian.data()[6 * input.data.correspondences.size()]);

            for (int j = 0; j < input.us.size() / 2; ++j) {
                engine.finite_differences_continue([&](double* us_in, double* err) {
                    // us_in points into the middle of _input.us.data()
                    hand_objective(input.theta.data(), input.us.data(), input.data, err);
                    }, &input.us.data()[j * 2], 2, result.objective.data(), result.objective.size(), jacobian_by_us.data());

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
                }, input.theta.data(), input.theta.size(), result.objective.data(), result.objective.size(), result.jacobian.data());
        }
    }
}

extern "C" DLL_PUBLIC ITest<HandInput, HandOutput>* get_hand_test()
{
    return new FiniteEigenHand();
}
