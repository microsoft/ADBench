#include <algorithm>
#include <iostream>
#include <limits>
#include <string>
#include <chrono>
#include <set>

#include "../shared/GMMData.h"
#include "../shared/ITest.h"
#include "../shared/utils.h"

#include "ModuleLoader.h"

using std::chrono::high_resolution_clock;
using std::chrono::duration;
using std::chrono::duration_cast;


GMMInput read_gmm_data(const string& input_file, const bool replicate_point)
{
    GMMInput input;

    // Read instance
    read_gmm_instance(input_file, &input.d, &input.k, &input.n,
        input.alphas, input.means, input.icf, input.x, input.wishart, replicate_point);

    return input;
}

typedef void (ITest<GMMInput, GMMOutput>::* test_member_function) (int);

void call_member_function(unique_ptr<ITest<GMMInput, GMMOutput>>& ptr_to_object, const test_member_function ptr_to_member, const int arg1) {
    (*(ptr_to_object).*(ptr_to_member))(arg1);
}

double measure_shortest_time(const double minimum_measurable_time, const int nruns, const double time_limit, unique_ptr<ITest<GMMInput, GMMOutput>>& test, const test_member_function func)
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

void save_objective_to_file(const string& filepath, const double value)
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

void check_test_support(const string& test_type) {
    std::set<string> supported_test_types = {
        "BA",
        "GMM"
    };
    if (supported_test_types.find(test_type) == supported_test_types.end()) {
        throw exception(("Cpp runner doesn't support a test of " + test_type + " type").c_str());
    }
}


int main(const int argc, const char* argv[])
{
    try {
        if (argc < 9) {
            std::cerr << "usage: CPPRunner test_type module_path input_filepath output_dir minimum_measurable_time nruns_F nruns_J time_limit [-rep]\n";
            return 1;
        }

        const string test_type(argv[1]);
        check_test_support(test_type);

        const auto module_path = argv[2];
        const string input_filepath(argv[3]);
        const string output_prefix(argv[4]);
        const auto minimum_measurable_time = std::stod(argv[5]);
        const auto nruns_F = std::stoi(argv[6]);
        const auto nruns_J = std::stoi(argv[7]);
        const auto time_limit = std::stod(argv[8]);

        // read only 1 point and replicate it?
        const auto replicate_point = (argc > 9 && string(argv[9]) == "-rep");

        ModuleLoader module_loader(module_path);
        auto test = module_loader.get_gmm_test();

        auto inputs = read_gmm_data(input_filepath, replicate_point);

        test->prepare(std::move(inputs));

        const auto objective_time =
            measure_shortest_time(minimum_measurable_time, nruns_F, time_limit, test, &ITest<GMMInput, GMMOutput>::calculateObjective);

        const auto derivative_time =
            measure_shortest_time(minimum_measurable_time, nruns_J, time_limit, test, &ITest<GMMInput, GMMOutput>::calculateJacobian);

        auto output = test->output();

        auto input_basename = filepath_to_basename(input_filepath);
        auto module_basename = filepath_to_basename(module_path);

        save_time_to_file(output_prefix + input_basename + "_times_" + module_basename + ".txt", objective_time, derivative_time);
        save_objective_to_file(output_prefix + input_basename + "_F_" + module_basename + ".txt", objective_time);
        save_gradient_to_file(output_prefix + input_basename + "_J_" + module_basename + ".txt", output.gradient);
    }
    catch (const std::exception& ex)
    {
        std::cout << "An exception caught: " << ex.what() << std::endl;
    }
    catch (const std::string& ex)
    {
        std::cout << "An exception caught: " << ex << std::endl;
    }
    catch (...)
    {
        std::cout << "Unhandled exception" << std::endl;
    }
}
