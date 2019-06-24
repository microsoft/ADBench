#include <gtest/gtest.h>
#include <gmock/gmock.h>

#include "../../../src/cpp/runner/ModuleLoader.h"
#include "../../../src/cpp/runner/Benchmark.h"
#include "MockGMM.h"
#include <thread>

using ::testing::_;

#ifdef _DEBUG
const auto module_path = "MockGMMd.dll";
#else
const auto module_path = "MockGMM.dll";
#endif

TEST(CppRunnerTests, LibraryLoadTest) {
    ModuleLoader module_loader(module_path);

    ASSERT_TRUE(module_loader.get_gmm_test() != nullptr);
}

TEST(CppRunnerTests, Execution) {
    ModuleLoader module_loader(module_path);

    auto gmm_test = module_loader.get_gmm_test();
    const auto minimum_measurable_time = 0.1;
    const auto run_count = 100;
    const auto time_limit = 100;

    EXPECT_CALL(dynamic_cast<MockGMM&>(*gmm_test.get()), calculateObjective(_))
        .Times(testing::Exactly(run_count))
        .WillRepeatedly(testing::Invoke([](auto a) { std::this_thread::sleep_for(0.01s); }));

    auto a = measure_shortest_time(minimum_measurable_time, run_count, time_limit, gmm_test, &ITest<GMMInput, GMMOutput>::calculateObjective);
}