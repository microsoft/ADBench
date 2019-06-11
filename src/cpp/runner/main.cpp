#include <iostream>
#include <string>

#include "../shared/GMMData.h"
#include "../shared/ITest.h"
#include "../shared/utils.h"

#include "ModuleLoader.h"

using namespace std;

GMMInput read_input_data(const string& input_file, const bool is_replicate_point)
{
	GMMInput input;

	// Read instance
	read_gmm_instance(input_file, &input.d, &input.k, &input.n,
		input.alphas, input.means, input.icf, input.x, input.wishart, is_replicate_point);
	return {};
}

int main(const int argc, const char* argv[])
{
	try {
		if (argc < 6) {
			std::cerr << "usage: CPPRunner module_path input_file output_file nruns_F nruns_J [-rep]\n";
			return 1;
		}

		const auto module_path = argv[1];
		const string input_file(argv[2]);
		const string output_file(argv[3]);

		// read only 1 point and replicate it?
		const auto is_replicate_point = (argc > 6 && string(argv[6]) == "-rep");

		ModuleLoader module_loader(module_path);
		auto test = module_loader.GetTest();

		auto inputs = read_input_data(input_file, is_replicate_point);

		test->output();
	}
	catch(string exception)
	{
		std::cout << "An exception caught: " << std::endl;
	}
	catch (...)
	{
		std::cout << "Unhandled exception" << std::endl;
	}
}
