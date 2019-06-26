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

TEST(CppRunnerTests, TimeLimit) {
    ModuleLoader module_loader(module_path);

    auto gmm_test = module_loader.get_gmm_test();
    const auto minimum_measurable_time = 0;
    const auto run_count = 100; //Run count guarantees total time greater than the time_limit
    const auto time_limit = 0.1s;
    const auto execution_time = 0.01s;

    EXPECT_CALL(dynamic_cast<MockGMM&>(*gmm_test.get()), calculateObjective(_))
        .Times(testing::AtMost(static_cast<int>(time_limit/execution_time))) //Number of runs should be less then run_count variable because total_time will be reached. 
        .WillRepeatedly(testing::Invoke([execution_time](auto a) { std::this_thread::sleep_for(execution_time); }));

    auto shortest_time = measure_shortest_time(minimum_measurable_time, run_count, time_limit.count(), gmm_test, &ITest<GMMInput, GMMOutput>::calculateObjective);
}

TEST(CppRunnerTests, TimeMeasurement) {
    ModuleLoader module_loader(module_path);

    auto gmm_test = module_loader.get_gmm_test();
    const auto minimum_measurable_time = 0.0000001;
    const auto run_count = 100;
    const auto time_limit = 100000;
    const auto execution_time = 0.01s;

    EXPECT_CALL(dynamic_cast<MockGMM&>(*gmm_test.get()), calculateObjective(_))
        .Times(testing::Exactly(run_count + 1))
        .WillRepeatedly(testing::Invoke([execution_time](auto a) { std::this_thread::sleep_for(execution_time); }));

    auto shortest_time = measure_shortest_time(minimum_measurable_time, run_count, time_limit, gmm_test, &ITest<GMMInput, GMMOutput>::calculateObjective);

    ASSERT_GE(shortest_time, execution_time.count());

}