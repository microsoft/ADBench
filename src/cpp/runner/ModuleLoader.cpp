#include "ModuleLoader.h"

ModuleLoader::ModuleLoader(const char* filePath)
{
    hModule = LoadLibraryA(filePath);
    if (hModule == NULL) {
        throw "Can't load library " + std::string(filePath);
    }
}

typedef ITest<GMMInput, GMMOutput>* (*GmmTestFuncPtr)();

std::unique_ptr<ITest<GMMInput, GMMOutput>> ModuleLoader::GetGmmTest() {
    auto GetGMMTest = (GmmTestFuncPtr)GetProcAddress(hModule,
        "GetGMMTest");
    if (GetGMMTest != NULL)
    {
        return std::unique_ptr<ITest<GMMInput, GMMOutput>>(GetGMMTest());
    }
    else
    {
        throw "Can't load GetGMMTest function";
    }
}

typedef ITest<BAInput, BAOutput>* (*BaTestFuncPtr)();

std::unique_ptr<ITest<BAInput, BAOutput>> ModuleLoader::GetBaTest() {
    auto GetBATest = (BaTestFuncPtr)GetProcAddress(hModule,
        "GetBATest");
    if (GetBATest != NULL)
    {
        return std::unique_ptr<ITest<BAInput, BAOutput>>(GetBATest());
    }
    else
    {
        throw "Can't load GetGMMTest function";
    }
}

ModuleLoader::~ModuleLoader()
{
    if (hModule != NULL)
    {
        FreeLibrary(hModule);
    }
}
