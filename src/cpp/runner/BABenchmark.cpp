// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#include "BABenchmark.h"

template <>
BAInput read_input_data<BAInput, DefaultParameters>(const std::string& input_file, const DefaultParameters& params)
{
    BAInput input;

    // Read instance
    read_ba_instance(input_file, input.n, input.m, input.p,
                     input.cams, input.X, input.w, input.obs, input.feats);

    return input;
}

template <>
unique_ptr<ITest<BAInput, BAOutput>> get_test<BAInput, BAOutput>(const ModuleLoader& module_loader)
{
    return module_loader.get_ba_test();
}

template <>
void save_output_to_file<BAOutput>(const BAOutput& output, const string& output_prefix, const string& input_basename,
                                   const string& module_basename)
{
    save_errors_to_file(objective_file_name(output_prefix, input_basename, module_basename), output.reproj_err,
                        output.w_err);
    save_sparse_j_to_file(jacobian_file_name(output_prefix, input_basename, module_basename), output.J);
}
