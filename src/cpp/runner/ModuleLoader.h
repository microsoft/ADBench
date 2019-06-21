#pragma once

#include <memory>
#include <string>
#include "Windows.h"
//Uncommenting macros defined in Windows.h to be able 
//to use functions whose name ends with "min" and "max".
#undef min
#undef max

#include "../shared/ITest.h"
#include "../shared/GMMData.h"
#include "../shared/BAData.h"

using namespace std;

class ModuleLoader {
    HINSTANCE hModule = nullptr;
public:
    ModuleLoader(const char* filePath);
    std::unique_ptr<ITest<GMMInput, GMMOutput>> GetGmmTest();
    std::unique_ptr<ITest<BAInput, BAOutput>> GetBaTest();
    ~ModuleLoader();
};