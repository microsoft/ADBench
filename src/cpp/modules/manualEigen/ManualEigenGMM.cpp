// ManualEigenGMM.cpp : Defines the exported functions for the DLL.
#include "ManualEigenGMM.h"
#include "../../shared/gmm.h"
#include "gmm_d.h"

#include <iostream>
#include <memory>

// This function must be called before any other function.
void ManualEigenGMM::prepare(GMMInput&& input)
{
    _input = input;
    int Jcols = (_input.k * (_input.d + 1) * (_input.d + 2)) / 2;
    _output = { 0,  std::vector<double>(Jcols) };
}

GMMOutput ManualEigenGMM::output()
{
    return _output;
}

void ManualEigenGMM::calculateObjective(int times)
{
    for (int i = 0; i < times; ++i) {
        gmm_objective(_input.d, _input.k, _input.n, _input.alphas.data(), _input.means.data(),
            _input.icf.data(), _input.x.data(), _input.wishart, &_output.objective);
    }
}

void ManualEigenGMM::calculateJacobian(int times)
{
    for (int i = 0; i < times; ++i) {
        gmm_objective_d(_input.d, _input.k, _input.n, _input.alphas.data(), _input.means.data(),
            _input.icf.data(), _input.x.data(), _input.wishart, &_output.objective, _output.gradient.data());
    }
}

extern "C" DLL_PUBLIC ITest<GMMInput, GMMOutput>* get_gmm_test()
{
    return new ManualEigenGMM();
}
