#include <iostream>
#include <string>

#include "ITest.h"
#include "ModuleLoader.h"

using namespace std;

int main(int argc, const char* argv[])
{
	if (argc < 2) {
		//std::cerr << "usage: CPPRunner moduleName dir_in dir_out file_basename nruns_F nruns_J [-rep]\n";
		std::cerr << "usage: CPPRunner modulePath\n";
		return 1;
	}

	auto modulePath = argv[1];

	ModuleLoader moduleLoader(modulePath);
	auto test = moduleLoader.GetTest();
	test->output();
}