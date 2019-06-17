#include <gtest/gtest.h>
#include "../../../../src/cpp/runner/ModuleLoader.h"

TEST(ManualGMMTests, LoadGMM) {
#ifdef _DEBUG
	ModuleLoader moduleLoader("Manuald.dll");
#else
	ModuleLoader moduleLoader("Manual.dll");
#endif
	auto test = moduleLoader.get_gmm_test();
	ASSERT_TRUE(test != NULL);
}

TEST(ManualGMMTests, LoadBA) {
#ifdef _DEBUG
	ModuleLoader moduleLoader("Manuald.dll");
#else
	ModuleLoader moduleLoader("Manual.dll");
#endif
	auto test = moduleLoader.get_ba_test();
	ASSERT_TRUE(test != NULL);
}