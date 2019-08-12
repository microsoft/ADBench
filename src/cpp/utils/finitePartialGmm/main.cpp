#include <iostream>
#include <string>
#include <algorithm>

#include "../../shared/ITest.h"
#include "../../shared/GMMData.h"
#include "../../shared/utils.h"
#include "../../shared/gmm.h"
#include "../../modules/finite/finite.h"
#include "../../runner/Filepaths.h"
#include "../../runner/OutputSave.h"

int main(const int argc, const char* argv[])
{
    try {
        if (argc < 4) {
            std::cerr << "usage: FinitePartialGmm input_filepath output_dir gradient_size_limit [-rep]\n";
            return 1;
        }
        const std::string input_filepath(argv[1]);
        const std::string output_prefix(argv[2]);
        const auto max_grad_size = std::stoi(argv[3]);

        const auto replicate_point = (argc > 4 && std::string(argv[4]) == "-rep");

        GMMInput input;

        // Read instance
        read_gmm_instance(input_filepath, &input.d, &input.k, &input.n,
            input.alphas, input.means, input.icf, input.x, input.wishart, replicate_point);

        int out_alphas = std::min(max_grad_size, input.k);
        int out_means = std::min(max_grad_size, input.d * input.k);
        int out_icfs = std::min(max_grad_size, (input.k * input.d * (input.d + 1)) / 2);
        double objective;
        std::vector<double> d_alphas(out_alphas), d_means(out_means), d_icfs(out_icfs);
        std::vector<int> positions{ 0, input.k , input.k + input.d * input.k };
        FiniteDifferencesEngine<double> engine(1);

        engine.finite_differences([&](double* alphas_in, double* err) {
            gmm_objective(input.d, input.k, input.n, alphas_in, input.means.data(), input.icf.data(), input.x.data(), input.wishart, err);
            }, input.alphas.data(), out_alphas, & objective, 1, d_alphas.data());// , FINITE_DIFFERENCES_DEFAULT_EPSILON, 4.0, 1.0);

        engine.finite_differences_continue([&](double* means_in, double* err) {
            gmm_objective(input.d, input.k, input.n, input.alphas.data(), means_in, input.icf.data(), input.x.data(), input.wishart, err);
            }, input.means.data(), out_means, &objective, 1, d_means.data());//, FINITE_DIFFERENCES_DEFAULT_EPSILON, 4.0, 1.0);

        engine.finite_differences_continue([&](double* icf_in, double* err) {
            gmm_objective(input.d, input.k, input.n, input.alphas.data(), input.means.data(), icf_in, input.x.data(), input.wishart, err);
            }, input.icf.data(), out_icfs, &objective, 1, d_icfs.data());//, FINITE_DIFFERENCES_DEFAULT_EPSILON, 4.0, 1.0);

        const auto input_basename = filepath_to_basename(input_filepath);
        std::ofstream out(jacobian_file_name(output_prefix, input_basename, "positions"));
        for (const auto& i : positions)
        {
            out << i << std::endl;
        }
        save_vector_to_file(jacobian_file_name(output_prefix, input_basename, "alphas"), d_alphas);
        save_vector_to_file(jacobian_file_name(output_prefix, input_basename, "means"), d_means);
        save_vector_to_file(jacobian_file_name(output_prefix, input_basename, "icfs"), d_icfs);
    }
    catch (const std::exception& ex)
    {
        std::cerr << "An exception caught: " << ex.what() << std::endl;
    }
    catch (const std::string& ex)
    {
        std::cerr << "An exception caught: " << ex << std::endl;
    }
    catch (...)
    {
        std::cerr << "Unknown exception" << std::endl;
    }
}