// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#include "ModuleLoader.h"

FUNCTION_PTR ModuleLoader::load_function(const std::string& symbol_name) const
{
#ifdef _WIN32
    return GetProcAddress(module_ptr_,
                          symbol_name.c_str());
#elif defined(__linux__) || defined(__APPLE__)
    return dlsym(module_ptr_, symbol_name.c_str());
#endif
}

ModuleLoader::ModuleLoader(const char* file_path)
{
#ifdef _WIN32
    module_ptr_ = LoadLibraryA(file_path);
#elif defined(__linux__) || defined(__APPLE__)
    module_ptr_ = dlopen(file_path, RTLD_NOW | RTLD_LOCAL);
#endif
    if (module_ptr_ == nullptr) {
        throw runtime_error(("Can't load library " + std::string(file_path)).c_str());
    }
}

typedef ITest<GMMInput, GMMOutput>* (*GmmTestFuncPtr)();

std::unique_ptr<ITest<GMMInput, GMMOutput>> ModuleLoader::get_gmm_test() const
{
    auto get_gmm_test = (GmmTestFuncPtr)load_function("get_gmm_test");
    if (get_gmm_test != nullptr)
    {
        return std::unique_ptr<ITest<GMMInput, GMMOutput>>(get_gmm_test());
    }
    else
    {
        throw runtime_error("Can't load get_gmm_test function");
    }
}

typedef ITest<BAInput, BAOutput>* (*BaTestFuncPtr)();

std::unique_ptr<ITest<BAInput, BAOutput>> ModuleLoader::get_ba_test() const
{
    auto get_ba_test = (BaTestFuncPtr)load_function("get_ba_test");
    if (get_ba_test != nullptr)
    {
        return std::unique_ptr<ITest<BAInput, BAOutput>>(get_ba_test());
    }
    else
    {
        throw runtime_error("Can't load get_ba_test function");
    }
}

typedef ITest<HandInput, HandOutput>* (*HandTestFuncPtr)();

std::unique_ptr<ITest<HandInput, HandOutput>> ModuleLoader::get_hand_test() const
{
    auto get_hand_test = (HandTestFuncPtr)load_function("get_hand_test");
    if (get_hand_test != nullptr)
    {
        return std::unique_ptr<ITest<HandInput, HandOutput>>(get_hand_test());
    }
    else
    {
        throw runtime_error("Can't load get_hand_test function");
    }
}

typedef ITest<LSTMInput, LSTMOutput>* (*LSTMTestFuncPtr)();

std::unique_ptr<ITest<LSTMInput, LSTMOutput>> ModuleLoader::get_lstm_test() const
{
    auto get_lstm_test = (LSTMTestFuncPtr)load_function("get_lstm_test");
    if (get_lstm_test != nullptr)
    {
        return std::unique_ptr<ITest<LSTMInput, LSTMOutput>>(get_lstm_test());
    }
    else
    {
        throw runtime_error("Can't load get_lstm_test function");
    }
}

ModuleLoader::~ModuleLoader()
{
    if (module_ptr_ != nullptr)
    {
#ifdef _WIN32
        FreeLibrary(module_ptr_);
#elif defined(__linux__) || defined(__APPLE__)
        dlclose(module_ptr_);
#endif
    }
}
