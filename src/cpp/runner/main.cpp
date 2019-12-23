// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#include <iostream>
#include <string>
#include <cctype>

#include "GMMBenchmark.h"
#include "BABenchmark.h"
#include "HandBenchmark.h"
#include "LSTMBenchmark.h"

std::string str_toupper(std::string s) {
    std::transform(s.begin(), s.end(), s.begin(),
        [](const unsigned char c) { return std::toupper(c); }
    );
    return s;
}

int main(const int argc, const char* argv[])
{
    try {
        if (argc < 9) {
            std::cerr << "usage: CPPRunner test_type module_path input_filepath output_dir minimum_measurable_time nruns_F nruns_J time_limit [-rep]\n";
            return 1;
        }

        const auto test_type = str_toupper(std::string(argv[1]));
        const auto module_path = argv[2];
        const string input_filepath(argv[3]);
        const string output_prefix(argv[4]);
        const auto minimum_measurable_time = duration<double>(std::stod(argv[5]));
        const auto nruns_F = std::stoi(argv[6]);
        const auto nruns_J = std::stoi(argv[7]);
        const auto time_limit = duration<double>(std::stod(argv[8]));

        // read only 1 point and replicate it?
        const auto replicate_point = (argc > 9 && string(argv[9]) == "-rep");

        if (test_type == "GMM") {
            run_benchmark<GMMInput, GMMOutput, GMMParameters>(module_path, input_filepath, output_prefix, minimum_measurable_time, nruns_F, nruns_J, time_limit, { replicate_point });
        }
        else if (test_type == "BA") {
            run_benchmark<BAInput, BAOutput>(module_path, input_filepath, output_prefix, minimum_measurable_time, nruns_F, nruns_J, time_limit);
        }
        else if (test_type == "HAND") {
            run_benchmark<HandInput, HandOutput, HandParameters>(module_path, input_filepath, output_prefix, minimum_measurable_time, nruns_F, nruns_J, time_limit, { false });
        }
        else if (test_type == "HAND-COMPLICATED") {
            run_benchmark<HandInput, HandOutput, HandParameters>(module_path, input_filepath, output_prefix, minimum_measurable_time, nruns_F, nruns_J, time_limit, { true });
        }
        else if (test_type == "LSTM") {
            run_benchmark<LSTMInput, LSTMOutput>(module_path, input_filepath, output_prefix, minimum_measurable_time, nruns_F, nruns_J, time_limit);
        }
        else
        {
            throw runtime_error(("C++ runner doesn't support tests of " + test_type + " type").c_str());
        }
    }
    catch (const std::exception& ex)
    {
        std::cerr << "An exception caught: " << ex.what() << std::endl;
    }
    catch (const std::string& ex)
    {
        std::cerr << "An exception caught: " << ex << std::endl;
    }
    catch (...)
    {
        std::cerr << "Unknown exception" << std::endl;
    }
}
