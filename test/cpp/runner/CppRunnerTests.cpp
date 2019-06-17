#include <gtest/gtest.h>
#include "../../../src/cpp/runner/ModuleLoader.h"

TEST(CppRunnerTests, LibraryLoadTest) {
#ifdef _DEBUG
    ModuleLoader moduleLoader("MockGMMd.dll");
#else
    ModuleLoader moduleLoader("MockGMM.dll");
#endif
	auto test = moduleLoader.get_gmm_test();
    ASSERT_TRUE(test != NULL);
}