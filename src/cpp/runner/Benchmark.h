#pragma once
#include <chrono>
#include "../shared/GMMData.h"
#include "../shared/ITest.h"
#include "ModuleLoader.h"
#include <algorithm>
#include "OutputSave.h"

using std::chrono::duration;
using std::chrono::duration_cast;
using std::chrono::high_resolution_clock;

template<class Input>
Input read_input_data(const std::string& input_file, bool replicate_point) = delete;

template <class Input, class Output>
using test_member_function = void (ITest<Input, Output>::*) (int);

template <class Input, class Output>
void call_member_function(std::unique_ptr<ITest<Input, Output>>& ptr_to_object, const test_member_function<Input, Output> ptr_to_member, const int arg1) {
    (*(ptr_to_object).*(ptr_to_member))(arg1);
}

template<class Input, class Output>
unique_ptr<ITest<Input, Output>> get_test(const ModuleLoader& module_loader)
{
    throw exception("Cpp runner doesn't support such test type yet");
}

template<class Input, class Output>
double measure_shortest_time(const double minimum_measurable_time, const int nruns, const double time_limit, std::unique_ptr<ITest<Input, Output>>& test, const test_member_function<Input, Output> func)
{
    auto min_sample = std::numeric_limits<double>::max();
    double total_time = 0;
    auto repeats = 1;
    while (repeats < (1 << 30))
    {
        auto t1 = high_resolution_clock::now();
        call_member_function(test, func, repeats);
        auto t2 = high_resolution_clock::now();
        const auto current_run_time = duration_cast<duration<double>>(t2 - t1).count();
        if (current_run_time > minimum_measurable_time)
        {
            min_sample = std::min(min_sample, current_run_time / repeats);
            total_time += current_run_time;
            break;
        }
        repeats *= 2;
    }

    for (auto run = 1; (run < nruns) && (total_time < time_limit); run++)
    {
        auto t1 = high_resolution_clock::now();
        call_member_function(test, func, repeats);
        auto t2 = high_resolution_clock::now();
        const auto current_run_time = duration_cast<duration<double>>(t2 - t1).count();
        min_sample = std::min(min_sample, current_run_time / repeats);
        total_time += current_run_time;
    }

    return min_sample;
}

template<class Output>
void save_output_to_file(const Output& output, const string& output_prefix, const string& input_basename, const string& module_basename) = delete;

std::string filepath_to_basename(const std::string& filepath);

template<class Input, class Output>
void run_benchmark(const char* const module_path, const std::string& input_filepath, const std::string& output_prefix, const double minimum_measurable_time, const int nruns_F, const int nruns_J,
    const double time_limit, const bool replicate_point) {

    const ModuleLoader module_loader(module_path);
    auto test = get_test<Input, Output>(module_loader);
    auto inputs = read_input_data<Input>(input_filepath, replicate_point);

    test->prepare(std::move(inputs));


    const auto objective_time =
        measure_shortest_time(minimum_measurable_time, nruns_F, time_limit, test, &ITest<Input, Output>::calculateObjective);

    const auto derivative_time =
        measure_shortest_time(minimum_measurable_time, nruns_J, time_limit, test, &ITest<Input, Output>::calculateJacobian);


    const auto output = test->output();


    const auto input_basename = filepath_to_basename(input_filepath);
    const auto module_basename = filepath_to_basename(module_path);

    save_time_to_file(output_prefix + input_basename + "_times_" + module_basename + ".txt", objective_time, derivative_time);
    save_output_to_file(output, output_prefix, input_basename, module_basename);    
}