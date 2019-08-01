// FiniteGMM.cpp : Defines the exported functions for the DLL.
#include "FiniteGMM.h"
#include "../../shared/gmm.h"
#include "finite.h"

// This function must be called before any other function.
void FiniteGMM::prepare(GMMInput&& input)
{
    _input = input;
    int Jcols = (_input.k * (_input.d + 1) * (_input.d + 2)) / 2;
    _output = { 0,  std::vector<double>(Jcols) };
}

GMMOutput FiniteGMM::output()
{
    return _output;
}

void FiniteGMM::calculateObjective(int times)
{
    for (int i = 0; i < times; ++i) {
        gmm_objective(_input.d, _input.k, _input.n, _input.alphas.data(), _input.means.data(),
            _input.icf.data(), _input.x.data(), _input.wishart, &_output.objective);
    }
}

void FiniteGMM::calculateJacobian(int times)
{
    for (int i = 0; i < times; ++i) {
        finite_differences<double>([&](double* alphas_in, double* err) {
            gmm_objective(_input.d, _input.k, _input.n, alphas_in, _input.means.data(), _input.icf.data(), _input.x.data(), _input.wishart, err);
            }, _input.alphas.data(), _input.alphas.size(), &_output.objective, 1, _output.gradient.data());

        finite_differences<double>([&](double* means_in, double* err) {
            gmm_objective(_input.d, _input.k, _input.n, _input.alphas.data(), means_in, _input.icf.data(), _input.x.data(), _input.wishart, err);
            }, _input.means.data(), _input.means.size(), &_output.objective, 1, &_output.gradient.data()[_input.k]);

        finite_differences<double>([&](double* icf_in, double* err) {
            gmm_objective(_input.d, _input.k, _input.n, _input.alphas.data(), _input.means.data(), icf_in, _input.x.data(), _input.wishart, err);
            }, _input.icf.data(), _input.icf.size(), &_output.objective, 1, &_output.gradient.data()[_input.k + _input.d * _input.k]);
    }
}

extern "C" DLL_PUBLIC ITest<GMMInput, GMMOutput>* GetGMMTest()
{
    return new FiniteGMM();
}
