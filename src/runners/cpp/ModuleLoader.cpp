#include "ModuleLoader.h"

ModuleLoader::ModuleLoader(const char* filePath)
{
	hModule = LoadLibraryA(filePath);
}

typedef std::unique_ptr<IGMMTest>(*LPFNDLLFUNC1)();

std::unique_ptr<IGMMTest> ModuleLoader::GetTest() {
	auto a = GetProcAddress(hModule,
		"GetGMMTest");
	auto GetGMMTest = (LPFNDLLFUNC1)GetProcAddress(hModule,
		"GetGMMTest");
	if (NULL != GetGMMTest)
	{
		return GetGMMTest();
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
