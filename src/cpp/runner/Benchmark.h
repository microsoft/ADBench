// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once
#include <chrono>
#include "../shared/ITest.h"
#include "ModuleLoader.h"
#include <algorithm>
#include "OutputSave.h"
#include "Filepaths.h"

using std::chrono::duration;
using std::chrono::duration_cast;
using std::chrono::high_resolution_clock;

/*
 * General logic of the benchmark described in this file.
 * However, functions responsible for data reading and outputting,
 * as well as for obtaining a test instance, must be implemented for each specific data type.
 * Such functions are implemented in <test_type>Benchmark.cpp files.
 */

struct DefaultParameters {};

 //Reads input_file into Input struct. replicate_point flag duplicates one vector over all input data.
 //Templated function "read_input_data" is deleted to cause a link error if a corresponding template specialization is not implemented.
template<class Input, class Parameters>
Input read_input_data(const std::string& input_file, const Parameters& params) = delete;

//Template of a pointer to a function which is a member of the ITest class and takes a single argument of int type.
template <class Input, class Output>
using test_member_function = void (ITest<Input, Output>::*) (int);

//This function calls a member of ITest class passing 1 int argument.
template <class Input, class Output>
void call_member_function(ITest<Input, Output>& ref_to_object,
                          const test_member_function<Input, Output> ptr_to_member, const int arg1) {
    (ref_to_object.*(ptr_to_member))(arg1);
}

//Makes a request to the ModuleLoader to get a test of a desired type.
//Templated function "get_test" is deleted to cause a link error if a corresponding template specialization is not implemented.
template<class Input, class Output>
unique_ptr<ITest<Input, Output>> get_test(const ModuleLoader& module_loader) = delete;

static constexpr auto measurable_time_not_achieved{ -1 };

template<class Input, class Output>
auto find_repeats_for_minimum_measurable_time(const duration<double> minimum_measurable_time,
                                              ITest<Input, Output>& test,
                                              const test_member_function<Input, Output> func)
{
    auto total_time = duration<double>(0s);
    auto min_sample = duration<double>(std::numeric_limits<double>::max());

    auto repeats = 1;
    constexpr auto max_possible_power_of_two = (std::numeric_limits<decltype(repeats)>::max() >> 1) + 1;
    do
    {
        auto t1 = high_resolution_clock::now();
        call_member_function(test, func, repeats);
        auto t2 = high_resolution_clock::now();
        //Time in seconds
        const auto current_run_time = duration_cast<duration<double>>(t2 - t1);
        if (current_run_time > minimum_measurable_time)
        {
            const auto current_sample = current_run_time / repeats;
            min_sample = std::min(min_sample, duration_cast<duration<double>>(current_sample));
            total_time += current_run_time;
            break;
        }
        //The next iteration will overflow a loop counter that's why we recognize that we cannot reach the minimum measurable time.
        if (repeats == max_possible_power_of_two)
        {
            repeats = measurable_time_not_achieved;
            break;
        }
        repeats *= 2;
    } while (repeats <= max_possible_power_of_two);

    struct result { int repeats; duration<double> sample; duration<double> total_time; };
    return result{ repeats, min_sample, total_time };
}

//Measures time according to the documentation.
template<class Input, class Output>
duration<double> measure_shortest_time(const duration<double> minimum_measurable_time, const int nruns,
                                       const duration<double> time_limit, ITest<Input, Output>& test,
                                       const test_member_function<Input, Output> func)
{
    auto find_repeats_result = find_repeats_for_minimum_measurable_time(minimum_measurable_time, test, func);

    if (find_repeats_result.repeats == measurable_time_not_achieved)
    {
        throw runtime_error("It was not possible to reach the number of repeats sufficient to achieve the minimum measurable time.");
    }

    auto repeats = find_repeats_result.repeats;
    auto min_sample = find_repeats_result.sample;

    // Recount `time_limit` and `run` from 0, despite "find_repeats_for_minimum_measurable_time",
    // because there might be lazy intializations
    auto total_time = duration<double>(0s);
    for (auto run = 0; (run < nruns) && (total_time < time_limit); run++)
    {
        auto t1 = high_resolution_clock::now();
        call_member_function(test, func, repeats);
        auto t2 = high_resolution_clock::now();
        //Time in seconds
        const auto current_run_time = t2 - t1;
        min_sample = std::min(min_sample, duration_cast<duration<double>>(current_run_time / repeats));
        total_time += current_run_time;
    }

    return min_sample;
}

//Templated function "save_output_to_file" is deleted to cause a link error if a corresponding template specialization is not implemented.
template<class Output>
void save_output_to_file(const Output& output, const string& output_prefix, const string& input_basename, const string& module_basename) = delete;

//Performs the entire benchmark process according to the documentation
template<class Input, class Output, class Parameters>
void run_benchmark(const char* module_path, const std::string& input_filepath, const std::string& output_prefix, const duration<double> minimum_measurable_time, const int nruns_F, const int nruns_J,
                   const duration<double> time_limit, const Parameters parameters) {

    const ModuleLoader module_loader(module_path);
    auto test = get_test<Input, Output>(module_loader);
    auto inputs = read_input_data<Input, Parameters>(input_filepath, parameters);

    test->prepare(std::move(inputs));

    const auto objective_time =
        measure_shortest_time(minimum_measurable_time, nruns_F, time_limit, *test, &ITest<Input, Output>::calculate_objective);

    const auto derivative_time =
        measure_shortest_time(minimum_measurable_time, nruns_J, time_limit, *test, &ITest<Input, Output>::calculate_jacobian);

    const auto output = test->output();

    const auto input_basename = filepath_to_basename(input_filepath);
    const auto module_basename = filepath_to_basename(module_path);

    save_time_to_file(output_prefix + input_basename + "_times_" + module_basename + ".txt", objective_time.count(), derivative_time.count());
    save_output_to_file(output, output_prefix, input_basename, module_basename);
}

template<class Input, class Output>
void run_benchmark(const char* const module_path, const std::string& input_filepath, const std::string& output_prefix, const duration<double> minimum_measurable_time, const int nruns_F, const int nruns_J,
                   const duration<double> time_limit) {
    run_benchmark<Input, Output, DefaultParameters>(module_path, input_filepath, output_prefix, minimum_measurable_time, nruns_F, nruns_J, time_limit, {});
}
