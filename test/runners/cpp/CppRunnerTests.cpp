#include <gtest/gtest.h>
#include "../../../src/runners/cpp/ModuleLoader.h"

TEST(CppRunnerTests, LibraryLoadTest) {
#ifdef _DEBUG
	ModuleLoader moduleLoader("GMMMockd.dll");
#else
	ModuleLoader moduleLoader("GMMMock.dll");
#endif
	auto test = moduleLoader.GetTest();
	EXPECT_EQ(test != NULL, true);
}