#include <gtest/gtest.h>
#include <gmock/gmock.h>

#include "../../../src/cpp/runner/ModuleLoader.h"
#include "../../../src/cpp/runner/Benchmark.h"
#include "MockGMM.h"
#include <thread>
#include <cmath>

using ::chrono::seconds;
using ::testing::_;

#ifdef _DEBUG
const auto module_path = "MockGMMd.dll";
#else
const auto module_path = "MockGMM.dll";
#endif

ModuleLoader module_loader(module_path);

TEST(CppRunnerTests, LibraryLoadTest) {
   
    ASSERT_TRUE(module_loader.get_gmm_test() != nullptr);
}

TEST(CppRunnerTests, TimeLimit) {

    auto gmm_test = module_loader.get_gmm_test();
    //Run_count guarantees total time greater than the time_limit
    const auto run_count = 100; 
    const auto time_limit = 0.1s;
    //Execution_time should be more than minimum_measurable_time 
    //because we can expect find_repeats_for_minimum_measurable_time to call calculateObjective function only once in that case.
    const auto minimum_measurable_time = 0s;
    const auto execution_time = 0.01s;

    EXPECT_CALL(dynamic_cast<MockGMM&>(*gmm_test.get()), calculateObjective(_))
        //Number of runs should be less then run_count variable because total_time will be reached. 
        .Times(testing::AtMost(static_cast<int>(std::ceil(time_limit / execution_time)))) 
        .WillRepeatedly(testing::Invoke([execution_time](auto a) { std::this_thread::sleep_for(execution_time); }));

    measure_shortest_time(minimum_measurable_time, run_count, time_limit, gmm_test, &ITest<GMMInput, GMMOutput>::calculateObjective);
}

TEST(CppRunnerTests, NumberOfRunsLimit) {

    auto gmm_test = module_loader.get_gmm_test();
    const auto minimum_measurable_time = 0s;
    const auto run_count = 10;
    const auto time_limit = 10s;
    const auto execution_time = 0.01s;

    EXPECT_CALL(dynamic_cast<MockGMM&>(*gmm_test.get()), calculateObjective(_))
        .Times(testing::Exactly(run_count)) //Number of runs should be equal to run_count limit.
        .WillRepeatedly(testing::Invoke([execution_time](auto a) { std::this_thread::sleep_for(execution_time); }));

    measure_shortest_time(minimum_measurable_time, run_count, time_limit, gmm_test, &ITest<GMMInput, GMMOutput>::calculateObjective);
}

TEST(CppRunnerTests, TimeMeasurement) {

    auto gmm_test = module_loader.get_gmm_test();
    const auto minimum_measurable_time = 0s;
    const auto run_count = 10;
    const auto time_limit = 100000s;
    const auto execution_time = 0.01s;

    EXPECT_CALL(dynamic_cast<MockGMM&>(*gmm_test.get()), calculateObjective(_))
        .Times(testing::Exactly(run_count + 1))
        .WillRepeatedly(testing::Invoke([execution_time](auto a) { std::this_thread::sleep_for(execution_time); }));

    auto shortest_time = measure_shortest_time(minimum_measurable_time, run_count, time_limit, gmm_test, &ITest<GMMInput, GMMOutput>::calculateObjective);

    ASSERT_GE(shortest_time, execution_time);
}

TEST(CppRunnerTests, SearchForRepeats) {

    auto gmm_test = module_loader.get_gmm_test();
    const auto assumed_repeats = 16;
    const auto execution_time = 0.01s;
    const auto minimum_measurable_time = execution_time*assumed_repeats;

    EXPECT_CALL(dynamic_cast<MockGMM&>(*gmm_test.get()), calculateObjective(_))
        .WillRepeatedly(testing::Invoke([execution_time](auto repeats) { std::this_thread::sleep_for(repeats*execution_time); }));

    auto result = find_repeats_for_minimum_measurable_time(minimum_measurable_time, gmm_test,
                                                           &ITest<GMMInput, GMMOutput>::calculateObjective);
    ASSERT_NE(result.repeats, measurable_time_not_achieved);
    ASSERT_LE(result.repeats, assumed_repeats);
}

TEST(CppRunnerTests, RepeatsNotFound) {

    auto gmm_test = module_loader.get_gmm_test();
    const auto minimum_measurable_time = 0.01s;

    auto result = find_repeats_for_minimum_measurable_time(minimum_measurable_time, gmm_test,
                                                           &ITest<GMMInput, GMMOutput>::calculateObjective);
    ASSERT_EQ(result.repeats, measurable_time_not_achieved);
}