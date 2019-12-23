// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#include "LSTMBenchmark.h"

template <>
LSTMInput read_input_data<LSTMInput, DefaultParameters>(const std::string& input_file, const DefaultParameters& params)
{
    LSTMInput input;

    // Read instance
    read_lstm_instance(input_file, &input.l, &input.c, &input.b, input.main_params, input.extra_params, input.state,
                       input.sequence);

    return input;
}

template <>
unique_ptr<ITest<LSTMInput, LSTMOutput>> get_test<LSTMInput, LSTMOutput>(const ModuleLoader& module_loader)
{
    return module_loader.get_lstm_test();
}

template <>
void save_output_to_file<LSTMOutput>(const LSTMOutput& output, const string& output_prefix,
                                     const string& input_basename, const string& module_basename)
{
    save_value_to_file(objective_file_name(output_prefix, input_basename, module_basename), output.objective);
    save_vector_to_file(jacobian_file_name(output_prefix, input_basename, module_basename), output.gradient);
}
