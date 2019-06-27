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
#include "../shared/HandData.h"

using namespace std;

class ModuleLoader {
    HINSTANCE hModule = nullptr;
public:
    ModuleLoader(const char* file_path);
    std::unique_ptr<ITest<GMMInput, GMMOutput>> get_gmm_test() const;
    std::unique_ptr<ITest<BAInput, BAOutput>> get_ba_test() const;
    std::unique_ptr<ITest<HandInput, HandOutput>> get_hand_test() const;
    ~ModuleLoader();
};