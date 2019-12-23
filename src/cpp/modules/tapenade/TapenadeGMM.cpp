// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#include "TapenadeGMM.h"

// This function must be called before any other function.
void TapenadeGMM::prepare(GMMInput&& input)
{
    this->input = input;
    int Jcols = (this->input.k * (this->input.d + 1) * (this->input.d + 2)) / 2;
    result = { 0, std::vector<double>(Jcols) };
}



GMMOutput TapenadeGMM::output()
{
    return result;
}



void TapenadeGMM::calculate_objective(int times)
{
    for (int i = 0; i < times; i++)
    {
        gmm_objective(
            input.d,
            input.k,
            input.n,
            input.alphas.data(),
            input.means.data(),
            input.icf.data(),
            input.x.data(),
            input.wishart,
            &result.objective
        );
    }
}



void TapenadeGMM::calculate_jacobian(int times)
{
    double* alphas_gradient_part = result.gradient.data();
    double* means_gradient_part = result.gradient.data() + input.alphas.size();
    double* icf_gradient_part =
        result.gradient.data() +
        input.alphas.size() +
        input.means.size();

    for (int i = 0; i < times; i++)
    {
        double tmp = 0.0;       // stores fictive result
                                // (Tapenade doesn't calculate an original function in reverse mode)

        double errb = 1.0;      // stores dY
                                // (equals to 1.0 for gradient calculation)

        gmm_objective_b(
            input.d,
            input.k,
            input.n,
            input.alphas.data(),
            alphas_gradient_part,
            input.means.data(),
            means_gradient_part,
            input.icf.data(),
            icf_gradient_part,
            input.x.data(),
            input.wishart,
            &tmp,
            &errb
        );
    }
}



extern "C" DLL_PUBLIC ITest<GMMInput, GMMOutput>* get_gmm_test()
{
    return new TapenadeGMM();
}