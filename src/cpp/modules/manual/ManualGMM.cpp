// ManualGMM.cpp : Defines the exported functions for the DLL.
#include "ManualGMM.h"
#include "../../shared/gmm.h"
#include "gmm_d.h"

#include <iostream>
#include <memory>

// This function must be called before any other function.
void ManualGMM::prepare(GMMInput&& input)
{
    _input = input;
    int Jcols = (_input.k * (_input.d + 1) * (_input.d + 2)) / 2;
    _J = std::vector<double>(Jcols);
}

GMMOutput ManualGMM::output()
{
    return { _f, _J };
}

void ManualGMM::calculateObjective(int times)
{
    for (int i = 0; i < times; ++i) {
        gmm_objective(_input.d, _input.k, _input.n, _input.alphas.data(), _input.means.data(),
            _input.icf.data(), _input.x.data(), _input.wishart, &_f);
    }
}

void ManualGMM::calculateJacobian(int times)
{
    for (int i = 0; i < times; ++i) {
        gmm_objective_d(_input.d, _input.k, _input.n, _input.alphas.data(), _input.means.data(),
            _input.icf.data(), _input.x.data(), _input.wishart, &_f, _J.data());
    }
}

extern "C" __declspec(dllexport) ITest<GMMInput, GMMOutput>* __cdecl GetGMMTest()
{
    return new ManualGMM();
}
