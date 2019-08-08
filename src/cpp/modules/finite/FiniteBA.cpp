// FiniteBA.cpp : Defines the exported functions for the DLL.
#include "FiniteBA.h"
#include "../../shared/ba.h"
#include "finite.h"

// This function must be called before any other function.
void FiniteBA::prepare(BAInput&& input)
{
    this->input = input;
    result = { std::vector<double>(2 * this->input.p), std::vector<double>(this->input.p), BASparseMat(this->input.n, this->input.m, this->input.p) };
    int n_new_cols = BA_NCAMPARAMS + 3 + 1;
    reproj_err_d = std::vector<double>(2 * n_new_cols);
    engine.set_max_output_size(2);
}

BAOutput FiniteBA::output()
{
    return result;
}

void FiniteBA::calculate_objective(int times)
{
    for (int i = 0; i < times; ++i) {
        ba_objective(input.n, input.m, input.p, input.cams.data(), input.X.data(), input.w.data(),
            input.obs.data(), input.feats.data(), result.reproj_err.data(), result.w_err.data());
    }
}

void FiniteBA::calculate_jacobian(int times)
{
    for (int i = 0; i < times; ++i) {
        result.J.clear();
        for (int j = 0; j < input.p; ++j)
        {
            std::fill(reproj_err_d.begin(), reproj_err_d.end(), (double)0);

            int camIdx = input.obs[2 * j + 0];
            int ptIdx = input.obs[2 * j + 1];

            engine.finite_differences([&](double* cam_in, double* reproj_err) {
                computeReprojError(cam_in, &input.X[ptIdx * 3], &input.w[j], &input.feats[2 * j], reproj_err);
                }, &input.cams[camIdx * BA_NCAMPARAMS], BA_NCAMPARAMS, &result.reproj_err[2 * j], 2, reproj_err_d.data());

            engine.finite_differences_continue([&](double* X_in, double* reproj_err) {
                computeReprojError(&input.cams[camIdx * BA_NCAMPARAMS], X_in, &input.w[j], &input.feats[2 * j], reproj_err);
                }, &input.X[ptIdx * 3], 3, &result.reproj_err[2 * j], 2, &reproj_err_d.data()[2 * BA_NCAMPARAMS]);

            engine.finite_differences_continue([&](double* w_in, double* reproj_err) {
                computeReprojError(&input.cams[camIdx * BA_NCAMPARAMS], &input.X[ptIdx * 3], w_in, &input.feats[2 * j], reproj_err);
                }, &input.w[j], 1, &result.reproj_err[2 * j], 2, &reproj_err_d.data()[2 * (BA_NCAMPARAMS + 3)]);

            result.J.insert_reproj_err_block(j, camIdx, ptIdx, reproj_err_d.data());
        }

        double w_d;

        for (int j = 0; j < input.p; ++j)
        {
            engine.finite_differences([&](double* w_in, double* w_er) {
                computeZachWeightError(w_in, w_er);
                }, &input.w[j], 1, &result.w_err[j], 1, &w_d);

            result.J.insert_w_err_block(j, w_d);
        }
    }
}

extern "C" DLL_PUBLIC ITest<BAInput, BAOutput>* get_ba_test()
{
    return new FiniteBA();
}
