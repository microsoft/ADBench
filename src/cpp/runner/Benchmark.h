#pragma once
#include <chrono>
#include "../shared/GMMData.h"
#include "../shared/ITest.h"
#include "ModuleLoader.h"
#include <algorithm>

using std::chrono::duration;
using std::chrono::duration_cast;
using std::chrono::high_resolution_clock;

GMMInput read_gmm_data(const std::string& input_file, const bool replicate_point)
{
    GMMInput input;

    // Read instance
    read_gmm_instance(input_file, &input.d, &input.k, &input.n,
        input.alphas, input.means, input.icf, input.x, input.wishart, replicate_point);

    return input;
}

template<class Input>
Input read_input_data(const std::string& input_file, const bool replicate_point)
{
    throw exception("Cpp runner doesn't support such input type yet");
}

template<>
inline GMMInput read_input_data<GMMInput>(const std::string& input_file, const bool replicate_point)
{
    return read_gmm_data(input_file, replicate_point);
}

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

template<>
unique_ptr <ITest<GMMInput, GMMOutput>> get_test<GMMInput, GMMOutput>(const ModuleLoader& module_loader)
{
    return module_loader.get_gmm_test();
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

std::string filepath_to_basename(const std::string& filepath)
{
    const auto last_slash_position = filepath.find_last_of("/\\");
    const auto filename = last_slash_position == std::string::npos
        ? filepath
        : filepath.substr(last_slash_position + 1);

    const auto dot = filename.find_last_of('.');
    const auto basename = dot == std::string::npos
        ? filename
        : filename.substr(0, dot);

    return basename;
}

void save_time_to_file(const string& filepath, const double objective_time, const double derivative_time)
{
    std::ofstream out(filepath);
    out << std::scientific << objective_time << std::endl << derivative_time;
    out.close();
}

void save_objective_to_file(const string& filepath, const double& value)
{
    std::ofstream out(filepath);
    out << std::scientific << value;
    out.close();
}

void save_gradient_to_file(const string& filepath, const vector<double>& gradient)
{
    std::ofstream out(filepath);

    for (const auto& i : gradient)
    {
        out << std::scientific << i << std::endl;
    }

    out.close();
}

template<class Output>
void save_output_to_file(const Output& output, const string& output_prefix, const string& input_basename, const string& module_basename) = delete;

template<>
void save_output_to_file<GMMOutput>(const GMMOutput& output, const string& output_prefix, const string& input_basename, const string& module_basename)
{
    save_objective_to_file(output_prefix + input_basename + "_F_" + module_basename + ".txt", output.objective);
    save_gradient_to_file(output_prefix + input_basename + "_J_" + module_basename + ".txt", output.gradient);
}

template<>
void save_output_to_file<BAOutput>(const BAOutput& output, const string& output_prefix, const string& input_basename, const string& module_basename)
{
    //save_objective_to_file(output_prefix + input_basename + "_F_" + module_basename + ".txt", output.);
    //save_gradient_to_file(output_prefix + input_basename + "_J_" + module_basename + ".txt", output.gradient);
    write_J_sparse(output_prefix + input_basename + "_J_" + module_basename + ".txt", output.J);
}

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