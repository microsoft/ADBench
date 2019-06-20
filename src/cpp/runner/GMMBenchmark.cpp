#include "GMMBenchmark.h"

template <>
GMMInput read_input_data<GMMInput>(const std::string& input_file, const bool replicate_point)
{
    GMMInput input;

    // Read instance
    read_gmm_instance(input_file, &input.d, &input.k, &input.n,
        input.alphas, input.means, input.icf, input.x, input.wishart, replicate_point);

    return input;
}

template <>
unique_ptr<ITest<GMMInput, GMMOutput>> get_test<GMMInput, GMMOutput>(const ModuleLoader& module_loader)
{
    return module_loader.get_gmm_test();
}

template <>
void save_output_to_file<GMMOutput>(const GMMOutput& output, const string& output_prefix, const string& input_basename,
                                    const string& module_basename)
{
    save_objective_to_file(output_prefix + input_basename + "_F_" + module_basename + ".txt", output.objective);
    save_gradient_to_file(output_prefix + input_basename + "_J_" + module_basename + ".txt", output.gradient);
}
