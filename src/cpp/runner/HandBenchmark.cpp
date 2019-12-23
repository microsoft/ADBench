// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#include "HandBenchmark.h"

template <>
HandInput read_input_data<HandInput, HandParameters>(const std::string& input_file, const HandParameters& params)
{
    HandInput input;

    const auto model_dir = filepath_to_dirname(input_file) + "model/";
    // Read instance
    if (params.is_complicated) {
        read_hand_instance(model_dir, input_file, &input.theta, &input.data, &input.us);
    }
    else {
        read_hand_instance(model_dir, input_file, &input.theta, &input.data);
    }

    return input;
}

template <>
unique_ptr<ITest<HandInput, HandOutput>> get_test<HandInput, HandOutput>(const ModuleLoader& module_loader)
{
    return module_loader.get_hand_test();
}

template <>
void save_output_to_file<HandOutput>(const HandOutput& output, const string& output_prefix,
                                     const string& input_basename, const string& module_basename)
{
    save_vector_to_file(objective_file_name(output_prefix, input_basename, module_basename), output.objective);
    save_jacobian_to_file(jacobian_file_name(output_prefix, input_basename, module_basename), output.jacobian_ncols, output.jacobian_nrows, output.jacobian);
}
