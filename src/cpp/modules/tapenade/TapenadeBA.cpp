// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#include "TapenadeBA.h"

// This function must be called before any other function.
void TapenadeBA::prepare(BAInput&& input)
{
    this->input = input;
    result = {
        std::vector<double>(2 * this->input.p),
        std::vector<double>(this->input.p),
        BASparseMat(this->input.n, this->input.m, this->input.p)
    };

    reproj_err_d = std::vector<double>(2 * (BA_NCAMPARAMS + 3 + 1));
    reproj_err_d_row = std::vector<double>(BA_NCAMPARAMS + 3 + 1);
}



BAOutput TapenadeBA::output()
{
    return result;
}



void TapenadeBA::calculate_objective(int times)
{
    for (int i = 0; i < times; i++)
    {
        ba_objective(
            input.n,
            input.m,
            input.p,
            input.cams.data(),
            input.X.data(),
            input.w.data(),
            input.obs.data(),
            input.feats.data(),
            result.reproj_err.data(),
            result.w_err.data()
        );
    }
}



void TapenadeBA::calculate_jacobian(int times)
{
    for (int i = 0; i < times; i++)
    {
        result.J.clear();
        calculate_reproj_error_jacobian_part();
        calculate_weight_error_jacobian_part();
    }
}



void TapenadeBA::calculate_reproj_error_jacobian_part()
{
    double errb[2];     // stores dY
                        // (i-th element equals to 1.0 for calculating i-th jacobian row)

    double err[2];      // stores fictive result
                        // (Tapenade doesn't calculate an original function in reverse mode)

    double* cam_gradient_part = reproj_err_d_row.data();
    double* x_gradient_part = reproj_err_d_row.data() + BA_NCAMPARAMS;
    double* weight_gradient_part = reproj_err_d_row.data() + BA_NCAMPARAMS + 3;

    for (int i = 0; i < input.p; i++)
    {
        int camIdx = input.obs[2 * i + 0];
        int ptIdx = input.obs[2 * i + 1];

        // calculate first row
        errb[0] = 1.0;
        errb[1] = 0.0;
        compute_reproj_error_b(
            &input.cams[camIdx * BA_NCAMPARAMS],
            cam_gradient_part,
            &input.X[ptIdx * 3],
            x_gradient_part,
            &input.w[i],
            weight_gradient_part,
            &input.feats[i * 2],
            err,
            errb
        );

        // fill first row elements
        for (int j = 0; j < BA_NCAMPARAMS + 3 + 1; j++)
        {
            reproj_err_d[2 * j] = reproj_err_d_row[j];
        }

        // calculate second row
        errb[0] = 0.0;
        errb[1] = 1.0;
        compute_reproj_error_b(
            &input.cams[camIdx * BA_NCAMPARAMS],
            cam_gradient_part,
            &input.X[ptIdx * 3],
            x_gradient_part,
            &input.w[i],
            weight_gradient_part,
            &input.feats[i * 2],
            err,
            errb
        );

        // fill second row elements
        for (int j = 0; j < BA_NCAMPARAMS + 3 + 1; j++)
        {
            reproj_err_d[2 * j + 1] = reproj_err_d_row[j];
        }

        result.J.insert_reproj_err_block(i, camIdx, ptIdx, reproj_err_d.data());
    }
}



void TapenadeBA::calculate_weight_error_jacobian_part()
{
    for (int j = 0; j < input.p; j++)
    {
        double wb;              // stores calculated derivative

        double err = 0.0;       // stores fictive result
                                // (Tapenade doesn't calculate an original function in reverse mode)

        double errb = 1.0;      // stores dY
                                // (equals to 1.0 for derivative calculation)

        compute_zach_weight_error_b(&input.w[j], &wb, &err, &errb);
        result.J.insert_w_err_block(j, wb);
    }
}



extern "C" DLL_PUBLIC ITest<BAInput, BAOutput>* get_ba_test()
{
    return new TapenadeBA();
}