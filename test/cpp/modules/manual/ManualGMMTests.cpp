#include <gtest/gtest.h>
#include "../../../../src/cpp/runner/ModuleLoader.h"

TEST(ManualGMMTests, LoadGMM) {
#ifdef _DEBUG
	ModuleLoader moduleLoader("Manuald.dll");
#else
	ModuleLoader moduleLoader("Manual.dll");
#endif
	auto test = moduleLoader.GetGmmTest();
	ASSERT_TRUE(test != NULL);
}

TEST(ManualGMMTests, LoadBA) {
#ifdef _DEBUG
	ModuleLoader moduleLoader("Manuald.dll");
#else
	ModuleLoader moduleLoader("Manual.dll");
#endif
	auto test = moduleLoader.GetBaTest();
	ASSERT_TRUE(test != NULL);
}