#include <gtest/gtest.h>
#include "../../../../src/cpp/runner/ModuleLoader.h"

TEST(ManualGMMTests, LibraryLoad) {
#ifdef _DEBUG
	ModuleLoader moduleLoader("ManualGMMd.dll");
#else
	ModuleLoader moduleLoader("ManualGMM.dll");
#endif
	auto test = moduleLoader.GetTest();
	ASSERT_TRUE(test != NULL);
}