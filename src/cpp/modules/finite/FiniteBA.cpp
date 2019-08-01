// FiniteBA.cpp : Defines the exported functions for the DLL.
#include "FiniteBA.h"
#include "../../shared/ba.h"
#include "finite.h"

// This function must be called before any other function.
void FiniteBA::prepare(BAInput&& input)
{
    _input = input;
    _output = { std::vector<double>(2 * _input.p), std::vector<double>(_input.p), BASparseMat(_input.n, _input.m, _input.p) };
    int n_new_cols = BA_NCAMPARAMS + 3 + 1;
    _reproj_err_d = std::vector<double>(2 * n_new_cols);
}

BAOutput FiniteBA::output()
{
    return _output;
}

void FiniteBA::calculateObjective(int times)
{
    for (int i = 0; i < times; ++i) {
        ba_objective(_input.n, _input.m, _input.p, _input.cams.data(), _input.X.data(), _input.w.data(),
            _input.obs.data(), _input.feats.data(), _output.reproj_err.data(), _output.w_err.data());
    }
}

void FiniteBA::calculateJacobian(int times)
{
    for (int i = 0; i < times; ++i) {
        _output.J.clear();
        for (int j = 0; j < _input.p; ++j)
        {
            std::fill(_reproj_err_d.begin(), _reproj_err_d.end(), (double)0);

            int camIdx = _input.obs[2 * j + 0];
            int ptIdx = _input.obs[2 * j + 1];

            finite_differences<double>([&](double* cam_in, double* reproj_err) {
                computeReprojError(cam_in, &_input.X[ptIdx * 3], &_input.w[j], &_input.feats[2 * j], reproj_err);
                }, &_input.cams[camIdx * BA_NCAMPARAMS], BA_NCAMPARAMS, &_output.reproj_err[2 * j], 2, _reproj_err_d.data());

            finite_differences<double>([&](double* X_in, double* reproj_err) {
                computeReprojError(&_input.cams[camIdx * BA_NCAMPARAMS], X_in, &_input.w[j], &_input.feats[2 * j], reproj_err);
                }, &_input.X[ptIdx * 3], 3, &_output.reproj_err[2 * j], 2, &_reproj_err_d.data()[2 * BA_NCAMPARAMS]);

            finite_differences<double>([&](double* w_in, double* reproj_err) {
                computeReprojError(&_input.cams[camIdx * BA_NCAMPARAMS], &_input.X[ptIdx * 3], w_in, &_input.feats[2 * j], reproj_err);
                }, &_input.w[j], 1, &_output.reproj_err[2 * j], 2, &_reproj_err_d.data()[2 * (BA_NCAMPARAMS + 3)]);

            _output.J.insert_reproj_err_block(j, camIdx, ptIdx, _reproj_err_d.data());
        }

        double w_d;

        for (int j = 0; j < _input.p; ++j)
        {
            finite_differences<double>([&](double* w_in, double* w_er) {
                computeZachWeightError(w_in, w_er);
                }, &_input.w[j], 1, &_output.w_err[j], 1, &w_d);

            _output.J.insert_w_err_block(j, w_d);
        }
    }
}

extern "C" DLL_PUBLIC ITest<BAInput, BAOutput>* GetBATest()
{
    return new FiniteBA();
}
