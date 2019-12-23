// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// ManualEigenVectorGMM.cpp : Defines the exported functions for the DLL.
#include "ManualEigenVectorGMM.h"
#include "../../shared/gmm.h"
#include "gmm_vector_d.h"
#include "memory_size.h"

#include <iostream>
#include <iomanip>
#include <memory>

// This function must be called before any other function.
void ManualEigenVectorGMM::prepare(GMMInput&& input)
{
    _input = input;
    int Jcols = (_input.k * (_input.d + 1) * (_input.d + 2)) / 2;
    _output = { 0,  std::vector<double>(Jcols) };

    // If there is not enough memory in the system to store
    // all the data structures that manualEigenVector needs,
    // then the execution will interrupt to prevent the system from deadlocking.
    unsigned long long int memory_size = get_memory_size();
    // If memory_size != 0 then compare it to the amount of memory we need,
    // otherwise consider it indeterminable and continue the execution.
    if (memory_size != 0) {
        unsigned long long int d = input.d;
        unsigned long long int k = input.k;
        unsigned long long int n = input.n;
        unsigned long long int icf_sz = d * (d + 1) / 2;
        unsigned long long int need_memory =
            (
            (k + k * d + k * icf_sz) // J
            + k + (d * k) + (d * n)  // eigen wrappers
            + k + (k * d * d) // sum_qs, Qs
            + (d * n) + (d * n) + (k * n) //xcentered, Qxcentered, main_term
            + (k * d * d) + (k * d * d) // tmp_means_d, tmp_qs_d
            + (k * (icf_sz - d) * n) // tmp_L_d
            + n + k // mX, semX
            ) * sizeof(double);
        // When the system doesn't have enough memory, running the test is not only pointless,
        // because the results will be spoiled by excessive swapping,
        // but may also be harmful to the functioning of the OS.
        // Too much memory pressure may (and does in practice) render the system unresponsive
        // and lead to the invocation of OOM Killer (or its equivalent).
        need_memory += 2UL * 1024UL * 1024UL * 1024UL; // + 2GB

        if (need_memory > memory_size) {
            double need_memory_in_GB = (long double)need_memory / 1024 / 1024 / 1024;
            std::cerr << "Not enough memory to run manualEigenVector module on this data." << "\n"
                << std::fixed << std::setprecision(3) << need_memory_in_GB
                << " GB of RAM is required to run this test." << "\n";
            std::exit(EXIT_FAILURE);
        }
    }
}

GMMOutput ManualEigenVectorGMM::output()
{
    return _output;
}

void ManualEigenVectorGMM::calculate_objective(int times)
{
    for (int i = 0; i < times; ++i) {
        gmm_objective(_input.d, _input.k, _input.n, _input.alphas.data(), _input.means.data(),
            _input.icf.data(), _input.x.data(), _input.wishart, &_output.objective);
    }
}

void ManualEigenVectorGMM::calculate_jacobian(int times)
{
    for (int i = 0; i < times; ++i) {
        gmm_objective_d(_input.d, _input.k, _input.n, _input.alphas.data(), _input.means.data(),
            _input.icf.data(), _input.x.data(), _input.wishart, &_output.objective, _output.gradient.data());
    }
}

extern "C" DLL_PUBLIC ITest<GMMInput, GMMOutput>* get_gmm_test()
{
    return new ManualEigenVectorGMM();
}
