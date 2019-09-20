#include "ModuleTest.h"

ModuleTest::~ModuleTest() { delete moduleLoader; }

void ModuleTest::SetUp()
{
    const char* modulePath;
    std::tie(modulePath, this->epsilon) = GetParam();
    moduleLoader = new ModuleLoader(modulePath);
}

void ModuleTest::TearDown()
{
    delete moduleLoader;
    moduleLoader = nullptr;
}