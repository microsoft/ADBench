#pragma once

#include <memory>
#include <string>
#include "Windows.h"
#undef min
#undef max

#include "../shared/ITest.h"
#include "../shared/GMMData.h"

using namespace std;

class ModuleLoader {
	HINSTANCE hModule = NULL;
public:
	ModuleLoader(const char* filePath);
	std::unique_ptr<ITest<GMMInput, GMMOutput>> GetTest();
	~ModuleLoader();
};