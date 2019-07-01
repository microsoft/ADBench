#pragma once

#include "Benchmark.h"

template <>
HandInput read_input_data<HandInput>(const std::string& input_file, const bool replicate_point);

template <>
unique_ptr<ITest<HandInput, HandOutput>> get_test<HandInput, HandOutput>(const ModuleLoader& module_loader);

template <>
void save_output_to_file<HandOutput>(const HandOutput& output, const string& output_prefix,
                                     const string& input_basename,
                                     const string& module_basename);
