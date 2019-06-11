#include <algorithm>
#include <iostream>
#include <string>

#include "../shared/GMMData.h"
#include "../shared/ITest.h"
#include "../shared/utils.h"

#include "ModuleLoader.h"

using namespace std;

GMMInput read_input_data(const string& input_file, const bool replicate_point)
{
    GMMInput input;

    // Read instance
    read_gmm_instance(input_file, &input.d, &input.k, &input.n,
        input.alphas, input.means, input.icf, input.x, input.wishart, replicate_point);

    return input;
}

double measure_shortest_time (const double minimum_measurable_time, const int nruns, const double time_limit, void (&func)(int))
{
    vector<double> samples;
    double total_time = 0;
    auto repeats = 1;
    for (;; repeats *= 2)
    {
        auto t1 = high_resolution_clock::now();
        func(repeats);
        auto t2 = high_resolution_clock::now();
        const auto current_run_time = duration_cast<duration<double>>(t2 - t1).count();
        if (current_run_time > minimum_measurable_time)
        {
            samples.push_back(current_run_time / repeats);
            total_time += current_run_time;
            break;
        }
    }


    for (auto run = 1; (run < nruns) && (total_time < time_limit); run++)
    {
        auto t1 = high_resolution_clock::now();
        func(repeats);
        auto t2 = high_resolution_clock::now();
        const auto current_run_time = duration_cast<duration<double>>(t2 - t1).count();
        samples.push_back(current_run_time / repeats);
        total_time += current_run_time;
    }

    const auto min_sample = *std::min_element(std::begin(samples), std::end(samples));

    return min_sample;
}

int main(const int argc, const char* argv[])
{
    try {
        if (argc < 8) {
            std::cerr << "usage: CPPRunner module_path input_file output_file minimum_measurable_time nruns_F nruns_J time_limit [-rep]\n";
            return 1;
        }

        const auto module_path = argv[1];
        const string input_file(argv[2]);
        const string output_file(argv[3]);
        const auto minimum_measurable_time = std::stod(argv[4]);
        const auto nruns_F = std::stoi(argv[5]);
        const auto nruns_J = std::stoi(argv[6]);
        const auto time_limit = std::stod(argv[7]);

        // read only 1 point and replicate it?
        const auto replicate_point = (argc > 8 && string(argv[8]) == "-rep");

        ModuleLoader module_loader(module_path);
        auto test = module_loader.GetTest();

        auto inputs = read_input_data(input_file, replicate_point);

        test->prepare(std::move(inputs));

        measure_shortest_time(minimum_measurable_time, nruns_F, time_limit, *(test->calculateObjective));
        measure_shortest_time(minimum_measurable_time, nruns_J, time_limit, *(test->calculateJacobian));

        test->output();
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
