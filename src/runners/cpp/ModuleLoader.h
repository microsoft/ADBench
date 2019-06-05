#pragma once

#include<memory>
#include <string>
#include "Windows.h"

#include "IGMMTest.h"

using namespace std;

class ModuleLoader {
	HINSTANCE hModule = NULL;
public:
	ModuleLoader(const char* filePath);
	std::unique_ptr<IGMMTest> GetTest();
	~ModuleLoader();
};