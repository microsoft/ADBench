#include <gtest/gtest.h>
#include "../../../src/runners/cpp/ModuleLoader.h"

TEST(CppRunnerTests, LibraryLoadTest) {
#ifdef _DEBUG
	ModuleLoader moduleLoader("MockGMMd.dll");
#else
	ModuleLoader moduleLoader("MockGMM.dll");
#endif
	auto test = moduleLoader.GetTest();
	EXPECT_EQ(test != NULL, true);
}