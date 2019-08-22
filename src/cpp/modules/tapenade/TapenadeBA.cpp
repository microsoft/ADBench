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

    cam_d = std::vector<double>(BA_NCAMPARAMS, 0.0);
    x_d = std::vector<double>(3, 0.0);
    w_d = std::vector<double>(1, 0.0);

    reproj_err_d = std::vector<double>(2 * (BA_NCAMPARAMS + 3 + 1));
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
    for (int i = 0; i < times; i++) {
        result.J.clear();

        // calculate reprojection error jacobian part
        for (int j = 0; j < input.p; j++)
        {
            std::fill(reproj_err_d.begin(), reproj_err_d.end(), 0.0);
            int camIdx = input.obs[2 * j + 0];
            int ptIdx = input.obs[2 * j + 1];

            compute_jacobian_reproj_block(j);
            result.J.insert_reproj_err_block(j, camIdx, ptIdx, reproj_err_d.data());
        }

        // calculate weight error jacobian part
        for (int j = 0; j < input.p; j++)
        {
            double w_d = 1.0;
            double err_d;

            compute_zach_weight_error_d(&input.w[j], &w_d, &result.w_err[j], &err_d);
            result.J.insert_w_err_block(j, err_d);
        }
    }
}



void TapenadeBA::compute_jacobian_reproj_block(int block)
{
    int shift;

    // calculate columns for camera
    shift = 0;
    compute_jacobian_columns(block, shift, cam_d);

    // calculate columns for point
    shift += 2 * BA_NCAMPARAMS;
    compute_jacobian_columns(block, shift, x_d);

    // calculate column for weight
    shift += 2 * 3;
    compute_jacobian_columns(block, shift, w_d);
}



void TapenadeBA::compute_jacobian_columns(int block, int shift, std::vector<double>& directions)
{
    int camIdx = input.obs[2 * block + 0];
    int ptIdx = input.obs[2 * block + 1];

    for (int i = 0; i < directions.size(); i++)
    {
        directions[i] = 1.0;    // set current direction
        if (i > 0)
        {
            directions[i - 1] = 0.0;    // erase last direction
        }

        compute_reproj_error_d(
            &input.cams[BA_NCAMPARAMS * camIdx],
            cam_d.data(),
            &input.X[ptIdx * 3],
            x_d.data(),
            &input.w[block],
            w_d.data(),
            &input.feats[2 * block],
            &result.reproj_err[2 * block],
            &reproj_err_d[shift + 2 * i]
        );
    }

    directions.back() = 0.0;        // erase last direction
}



extern "C" DLL_PUBLIC ITest<BAInput, BAOutput>* get_ba_test()
{
    return new TapenadeBA();
}