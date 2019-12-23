// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once

#include "Benchmark.h"

template <>
HandInput read_input_data<HandInput, HandParameters>(const std::string& input_file, const HandParameters& params);

template <>
unique_ptr<ITest<HandInput, HandOutput>> get_test<HandInput, HandOutput>(const ModuleLoader& module_loader);

template <>
void save_output_to_file<HandOutput>(const HandOutput& output, const string& output_prefix,
                                     const string& input_basename,
                                     const string& module_basename);
