#include <iostream>
#include <string>
#include <set>

#include "GMMBenchmark.h"
#include "BABenchmark.h"

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

        if (test_type == "GMM") {
            run_benchmark<GMMInput, GMMOutput>(module_path, input_filepath, output_prefix, minimum_measurable_time, nruns_F, nruns_J, time_limit, replicate_point);
        } else if (test_type == "BA") {
            run_benchmark<BAInput, BAOutput>(module_path, input_filepath, output_prefix, minimum_measurable_time, nruns_F, nruns_J, time_limit, replicate_point);
        }
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
        std::cout << "Unknown exception" << std::endl;
    }
}
