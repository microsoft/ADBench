// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// FiniteGMM.cpp : Defines the exported functions for the DLL.
#include "FiniteGMM.h"
#include "../../shared/gmm.h"
#include "finite.h"

// This function must be called before any other function.
void FiniteGMM::prepare(GMMInput&& input)
{
    this->input = input;
    int Jcols = (this->input.k * (this->input.d + 1) * (this->input.d + 2)) / 2;
    result = { 0,  std::vector<double>(Jcols) };
    engine.set_max_output_size(1);
}

GMMOutput FiniteGMM::output()
{
    return result;
}

void FiniteGMM::calculate_objective(int times)
{
    for (int i = 0; i < times; ++i) {
        gmm_objective(input.d, input.k, input.n, input.alphas.data(), input.means.data(),
            input.icf.data(), input.x.data(), input.wishart, &result.objective);
    }
}

void FiniteGMM::calculate_jacobian(int times)
{
    for (int i = 0; i < times; ++i) {
        engine.finite_differences([&](double* alphas_in, double* err) {
            gmm_objective(input.d, input.k, input.n, alphas_in, input.means.data(), input.icf.data(), input.x.data(), input.wishart, err);
            }, input.alphas.data(), input.alphas.size(), 1, result.gradient.data());

        engine.finite_differences([&](double* means_in, double* err) {
            gmm_objective(input.d, input.k, input.n, input.alphas.data(), means_in, input.icf.data(), input.x.data(), input.wishart, err);
            }, input.means.data(), input.means.size(), 1, &result.gradient.data()[input.k]);

        engine.finite_differences([&](double* icf_in, double* err) {
            gmm_objective(input.d, input.k, input.n, input.alphas.data(), input.means.data(), icf_in, input.x.data(), input.wishart, err);
            }, input.icf.data(), input.icf.size(), 1, &result.gradient.data()[input.k + input.d * input.k]);
    }
}

extern "C" DLL_PUBLIC ITest<GMMInput, GMMOutput>* get_gmm_test()
{
    return new FiniteGMM();
}
