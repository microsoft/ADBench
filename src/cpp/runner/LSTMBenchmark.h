// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once

#include "Benchmark.h"
#include "../shared/LSTMData.h"
#include "ModuleLoader.h"
#include "Filepaths.h"

template <>
LSTMInput read_input_data<LSTMInput, DefaultParameters>(const std::string& input_file, const DefaultParameters& params);

template <>
unique_ptr<ITest<LSTMInput, LSTMOutput>> get_test<LSTMInput, LSTMOutput>(const ModuleLoader& module_loader);

template <>
void save_output_to_file<LSTMOutput>(const LSTMOutput& output, const string& output_prefix,
                                     const string& input_basename, const string& module_basename);
