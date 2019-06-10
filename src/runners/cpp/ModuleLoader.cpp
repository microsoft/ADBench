#include "ModuleLoader.h"

ModuleLoader::ModuleLoader(const char* filePath)
{
	hModule = LoadLibraryA(filePath);
	if (hModule == NULL) {
		throw "Can't load library " + std::string(filePath);
	}
}

typedef ITest<GMMInput, GMMOutput>* (*LPFNDLLFUNC1)();

std::unique_ptr<ITest<GMMInput, GMMOutput>> ModuleLoader::GetTest() {
	auto GetGMMTest = (LPFNDLLFUNC1)GetProcAddress(hModule,
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

ModuleLoader::~ModuleLoader()
{
	if (hModule != NULL)
	{
		FreeLibrary(hModule);
	}
}
