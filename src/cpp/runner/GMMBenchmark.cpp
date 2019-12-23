// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#include "GMMBenchmark.h"

template <>
GMMInput read_input_data<GMMInput, GMMParameters>(const std::string& input_file, const GMMParameters& params)
{
    GMMInput input;

    // Read instance
    read_gmm_instance(input_file, &input.d, &input.k, &input.n,
        input.alphas, input.means, input.icf, input.x, input.wishart, params.replicate_point);

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
    save_value_to_file(objective_file_name(output_prefix, input_basename, module_basename), output.objective);
    save_vector_to_file(jacobian_file_name(output_prefix, input_basename, module_basename), output.gradient);
}
