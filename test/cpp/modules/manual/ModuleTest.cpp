#include "ModuleTest.h"

ModuleTest::~ModuleTest() { delete moduleLoader; }

void ModuleTest::SetUp()
{
    moduleLoader = new ModuleLoader(GetParam());
}

void ModuleTest::TearDown()
{
    delete moduleLoader;
    moduleLoader = nullptr;
}