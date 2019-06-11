#include <iostream>
#include <string>

#include "../shared/GMMData.h"
#include "../shared/ITest.h"
#include "../shared/utils.h"

#include "ModuleLoader.h"

using namespace std;

/*GMMOutput readInputData() {

}*/

int main(int argc, const char* argv[])
{
	if (argc < 7) {
		std::cerr << "usage: CPPRunner modulePath dir_in dir_out file_basename nruns_F nruns_J [-rep]\n";
		return 1;
	}

	auto modulePath = argv[1];
	string dir_in(argv[1]);
	string dir_out(argv[2]);

	ModuleLoader moduleLoader(modulePath);
	auto test = moduleLoader.GetTest();

	/*// Read instance
	auto inputs = readInputData();*/

	test->output();
}