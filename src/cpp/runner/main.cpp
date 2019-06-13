#include <algorithm>
#include <filesystem>
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

typedef  void (ITest<GMMInput, GMMOutput>::* test_member_function) (int);

inline void call_member_function(unique_ptr<ITest<GMMInput, GMMOutput>>& ptr_to_object, const test_member_function ptr_to_member, const int arg1) {
    (*(ptr_to_object).*(ptr_to_member))(arg1);
}

double measure_shortest_time(const double minimum_measurable_time, const int nruns, const double time_limit, unique_ptr<ITest<GMMInput, GMMOutput>>& test, const test_member_function func)
{
    vector<double> samples;
    double total_time = 0;
    auto repeats = 1;
    for (;; repeats *= 2)
    {
        auto t1 = high_resolution_clock::now();
        call_member_function(test, func, repeats);
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
        call_member_function(test, func, repeats);
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
        if (argc < 9) {
            std::cerr << "usage: CPPRunner module_path input_dir input_file output_dir minimum_measurable_time nruns_F nruns_J time_limit [-rep]\n";
            return 1;
        }

        const auto module_path = argv[1];
        const string input_dir(argv[2]);
        const string input_file(argv[3]);
        const string output_dir(argv[4]);
        const auto minimum_measurable_time = std::stod(argv[5]);
        const auto nruns_F = std::stoi(argv[6]);
        const auto nruns_J = std::stoi(argv[7]);
        const auto time_limit = std::stod(argv[8]);

        // read only 1 point and replicate it?
        const auto replicate_point = (argc > 9 && string(argv[9]) == "-rep");

        ModuleLoader module_loader(module_path);
        auto test = module_loader.GetTest();

        auto inputs = read_input_data(input_dir + input_file, replicate_point);

        test->prepare(std::move(inputs));

        measure_shortest_time(minimum_measurable_time, nruns_F, time_limit, test, &ITest<GMMInput, GMMOutput>::calculateObjective);
        measure_shortest_time(minimum_measurable_time, nruns_J, time_limit, test, &ITest<GMMInput, GMMOutput>::calculateJacobian);

        auto output = test->output();

        //write_times(output_dir +  + "_times_" + input_file + ".txt", tf, tJ);

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
