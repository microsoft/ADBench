// ManualEigenVectorGMM.cpp : Defines the exported functions for the DLL.
#include "ManualEigenVectorGMM.h"
#include "../../shared/gmm.h"
#include "gmm_vector_d.h"
#include "memory_size.h"

#include <iostream>
#include <memory>

// This function must be called before any other function.
void ManualEigenVectorGMM::prepare(GMMInput&& input)
{
    _input = input;
    int Jcols = (_input.k * (_input.d + 1) * (_input.d + 2)) / 2;
    _output = { 0,  std::vector<double>(Jcols) };

    // If it is not enough memory in system to store all data that
    // manualEigenVector need, then executing will interrupt
    // to prevent system deadlock
    unsigned long long int memory_size = get_memory_size();
    // If memory_size != 0 then check memory size,
    // else OS is undefined by get_memory_size()
    // and we try to execute module
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
        need_memory += 100 * 1024 * 1024; // + 100MB
        if (need_memory > memory_size) {
            need_memory /= 1024 * 1024 * 1024;
            std::cerr << "Not enough memory to run manualEigenVector module on this data." << "\n"
                << "Your system should have about " << need_memory << " GB of RAM." << "\n";
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

extern "C" __declspec(dllexport) ITest<GMMInput, GMMOutput>* __cdecl get_gmm_test()
{
    return new ManualEigenVectorGMM();
}
