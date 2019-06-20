#include <gtest/gtest.h>
#include "../../../../src/cpp/runner/ModuleLoader.h"

TEST(ManualEigenGMMTests, LibraryLoad) {
#ifdef _DEBUG
	ModuleLoader moduleLoader("ManualEigenGMMd.dll");
#else
	ModuleLoader moduleLoader("ManualEigenGMM.dll");
#endif
	auto test = moduleLoader.GetTest();
	ASSERT_TRUE(test != NULL);
}