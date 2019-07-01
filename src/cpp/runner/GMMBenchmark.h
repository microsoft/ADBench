#pragma once

#include "Benchmark.h"

template<>
GMMInput read_input_data<GMMInput>(const std::string& input_file, const bool replicate_point);

template<>
unique_ptr<ITest<GMMInput, GMMOutput>> get_test<GMMInput, GMMOutput>(const ModuleLoader& module_loader);

template<>
void save_output_to_file<GMMOutput>(const GMMOutput& output, const string& output_prefix, const string& input_basename,
                                    const string& module_basename);
