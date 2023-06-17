// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// ManualEigenBA.cpp : Defines the exported functions for the DLL.
#include "ManualEigenBA.h"
#include "../../shared/ba_eigen.h"
#include "ba_d.h"

constexpr int n_new_cols = BA_NCAMPARAMS + 3 + 1;

// This function must be called before any other function.
void ManualEigenBA::prepare(BAInput&& input)
{
    _input = input;
    _output = { std::vector<double>(2 * _input.p), std::vector<double>(_input.p), BASparseMat(_input.n, _input.m, _input.p) };
    _reproj_err_d = std::vector<double>(2 * n_new_cols * _input.p);
    _zach_weight_error_d = std::vector<double>(_input.p);
}

BAOutput ManualEigenBA::output()
{
    for (int i = 0; i < _input.p; ++i) {
        int camIdx = _input.obs[2 * i + 0];
        int ptIdx = _input.obs[2 * i + 1];
        _output.J.insert_reproj_err_block(i, camIdx, ptIdx, _reproj_err_d.data() + i * 2 * n_new_cols);
    }
    for (int i = 0; i < _input.p; ++i) {
        _output.J.insert_w_err_block(i, _zach_weight_error_d[i]);
    }
    return _output;
}

void ManualEigenBA::calculate_objective(int times)
{
    for (int i = 0; i < times; ++i) {
        ba_objective(_input.n, _input.m, _input.p, _input.cams.data(), _input.X.data(), _input.w.data(),
            _input.obs.data(), _input.feats.data(), _output.reproj_err.data(), _output.w_err.data());
    }
}

void ManualEigenBA::calculate_jacobian(int times)
{
    for (int t = 0; t < times; ++t) {
        _output.J.clear();
        for (int i = 0; i < _input.p; i++)
        {
            std::fill(_reproj_err_d.begin() + i * 2 * n_new_cols,
                      _reproj_err_d.begin() + (i + 1) * 2 * n_new_cols,
                      (double)0);

            int camIdx = _input.obs[2 * i + 0];
            int ptIdx = _input.obs[2 * i + 1];
            compute_reproj_error_d(
                &_input.cams[BA_NCAMPARAMS * camIdx],
                &_input.X[ptIdx * 3],
                _input.w[i],
                _input.feats[2 * i + 0], _input.feats[2 * i + 1],
                &_output.reproj_err[2 * i],
                _reproj_err_d.data() + i * 2 * n_new_cols);
        }

        for (int i = 0; i < _input.p; i++)
        {
            _zach_weight_error_d[i] = 0;
            compute_zach_weight_error_d(_input.w[i], &_output.w_err[i], &_zach_weight_error_d[i]);
        }
    }
}

extern "C" DLL_PUBLIC ITest<BAInput, BAOutput>* get_ba_test()
{
    return new ManualEigenBA();
}
