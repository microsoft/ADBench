// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once

#include "Benchmark.h"

template<>
GMMInput read_input_data<GMMInput, GMMParameters>(const std::string& input_file, const GMMParameters& params);

template<>
unique_ptr<ITest<GMMInput, GMMOutput>> get_test<GMMInput, GMMOutput>(const ModuleLoader& module_loader);

template<>
void save_output_to_file<GMMOutput>(const GMMOutput& output, const string& output_prefix, const string& input_basename,
                                    const string& module_basename);
