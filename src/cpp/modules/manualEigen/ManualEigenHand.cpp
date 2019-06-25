// ManualEigenHand.cpp : Defines the exported functions for the DLL.
#include "ManualEigenHand.h"
#include "../../shared/hand_eigen.h"
#include "hand_eigen_d.h"

#include <iostream>
#include <memory>

// This function must be called before any other function.
void ManualEigenHand::prepare(HandInput&& input)
{
    _input = input;
    int Jcols = (_input.k * (_input.d + 1) * (_input.d + 2)) / 2;
    _output = { 0,  std::vector<double>(Jcols) };
}

HandOutput ManualEigenHand::output()
{
    return _output;
}

void ManualEigenHand::calculateObjective(int times)
{
    for (int i = 0; i < times; ++i) {
        gmm_objective(_input.d, _input.k, _input.n, _input.alphas.data(), _input.means.data(),
            _input.icf.data(), _input.x.data(), _input.wishart, &_output.objective);
    }
}

void ManualEigenHand::calculateJacobian(int times)
{
    for (int i = 0; i < times; ++i) {
        gmm_objective_d(_input.d, _input.k, _input.n, _input.alphas.data(), _input.means.data(),
            _input.icf.data(), _input.x.data(), _input.wishart, &_output.objective, _output.gradient.data());
    }
}

extern "C" __declspec(dllexport) ITest<HandInput, HandOutput>* __cdecl GetHandTest()
{
    return new ManualEigenHand();
}
