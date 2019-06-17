#include "ModuleLoader.h"

ModuleLoader::ModuleLoader(const char* file_path)
{
	hModule = LoadLibraryA(file_path);
	if (hModule == nullptr) {
		throw exception(("Can't load library " + std::string(file_path)).c_str());
    }
}

typedef ITest<GMMInput, GMMOutput>* (*GmmTestFuncPtr)();

std::unique_ptr<ITest<GMMInput, GMMOutput>> ModuleLoader::get_gmm_test() const
{
    auto GetGMMTest = (GmmTestFuncPtr)GetProcAddress(hModule,
        "GetGMMTest");
	if (GetGMMTest != nullptr)
    {
        return std::unique_ptr<ITest<GMMInput, GMMOutput>>(GetGMMTest());
    }
    else
    {
		throw exception("Can't load GetGMMTest function");
    }
}

typedef ITest<BAInput, BAOutput>* (*BaTestFuncPtr)();

std::unique_ptr<ITest<BAInput, BAOutput>> ModuleLoader::get_ba_test() const
{
    auto GetBATest = (BaTestFuncPtr)GetProcAddress(hModule,
        "GetBATest");
	if (GetBATest != nullptr)
    {
        return std::unique_ptr<ITest<BAInput, BAOutput>>(GetBATest());
    }
    else
    {
		throw exception("Can't load GetGMMTest function");
    }
}

ModuleLoader::~ModuleLoader()
{
	if (hModule != nullptr)
    {
        FreeLibrary(hModule);
    }
}
