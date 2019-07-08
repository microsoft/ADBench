#include "ModuleLoader.h"

FUNCTION_PTR ModuleLoader::load_function(const std::string& symbol_name) const
{
#ifdef _WIN32
    return GetProcAddress(module_ptr_,
                          symbol_name.c_str());
#elif __linux__ 
    dlsym(module_ptr_, symbol_name.c_str());
#endif
}

ModuleLoader::ModuleLoader(const char* file_path)
{
#ifdef _WIN32
    module_ptr_ = LoadLibraryA(file_path);
#elif __linux__ 
    module_ptr_ = dlopen(file_path, RTLD_NOW || RTLD_LOCAL);
#endif
    if (module_ptr_ == nullptr) {
        throw runtime_error(("Can't load library " + std::string(file_path)).c_str());
    }
}

typedef ITest<GMMInput, GMMOutput>* (*GmmTestFuncPtr)();

std::unique_ptr<ITest<GMMInput, GMMOutput>> ModuleLoader::get_gmm_test() const
{
    auto GetGMMTest = (GmmTestFuncPtr)load_function("GetGMMTest");
    if (GetGMMTest != nullptr)
    {
        return std::unique_ptr<ITest<GMMInput, GMMOutput>>(GetGMMTest());
    }
    else
    {
        throw runtime_error("Can't load GetGMMTest function");
    }
}

typedef ITest<BAInput, BAOutput>* (*BaTestFuncPtr)();

std::unique_ptr<ITest<BAInput, BAOutput>> ModuleLoader::get_ba_test() const
{
    auto GetBATest = (BaTestFuncPtr)load_function("GetBATest");
    if (GetBATest != nullptr)
    {
        return std::unique_ptr<ITest<BAInput, BAOutput>>(GetBATest());
    }
    else
    {
        throw runtime_error("Can't load GetGMMTest function");
    }
}

typedef ITest<HandInput, HandOutput>* (*HandTestFuncPtr)();

std::unique_ptr<ITest<HandInput, HandOutput>> ModuleLoader::get_hand_test() const
{
    auto GetHandTest = (HandTestFuncPtr)load_function("GetHandTest");
    if (GetHandTest != nullptr)
    {
        return std::unique_ptr<ITest<HandInput, HandOutput>>(GetHandTest());
    }
    else
    {
        throw runtime_error("Can't load GetHandTest function");
    }
}

typedef ITest<LSTMInput, LSTMOutput>* (*LSTMTestFuncPtr)();

std::unique_ptr<ITest<LSTMInput, LSTMOutput>> ModuleLoader::get_lstm_test() const
{
    auto GetLSTMTest = (LSTMTestFuncPtr)load_function("GetLSTMTest");
    if (GetLSTMTest != nullptr)
    {
        return std::unique_ptr<ITest<LSTMInput, LSTMOutput>>(GetLSTMTest());
    }
    else
    {
        throw runtime_error("Can't load GetHandTest function");
    }
}

ModuleLoader::~ModuleLoader()
{
    if (module_ptr_ != nullptr)
    {
#ifdef _WIN32
        FreeLibrary(module_ptr_);
#elif __linux__ 
        dlclose(module_ptr_);
#endif
    }
}
