// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once

#include <memory>
#ifdef _WIN32
#include "Windows.h"
//Uncommenting macros defined in Windows.h to be able 
//to use functions whose name ends with "min" and "max".
#undef min
#undef max
#define MODULE_PTR HINSTANCE
#define FUNCTION_PTR FARPROC
#elif defined(__linux__) || defined(__APPLE__)
#include <dlfcn.h>
#define MODULE_PTR void*
#define FUNCTION_PTR void*
#endif

#include "../shared/ITest.h"
#include "../shared/GMMData.h"
#include "../shared/BAData.h"
#include "../shared/HandData.h"
#include "../shared/LSTMData.h"

using namespace std;

class ModuleLoader {
    MODULE_PTR module_ptr_ = nullptr;
    FUNCTION_PTR load_function(const std::string& symbol_name) const;
public:
    explicit ModuleLoader(const char* file_path);
    std::unique_ptr<ITest<GMMInput, GMMOutput>> get_gmm_test() const;
    std::unique_ptr<ITest<BAInput, BAOutput>> get_ba_test() const;
    std::unique_ptr<ITest<HandInput, HandOutput>> get_hand_test() const;
    std::unique_ptr<ITest<LSTMInput, LSTMOutput>> get_lstm_test() const;
    ~ModuleLoader();
};
