#include <gtest/gtest.h>
#include "../../../../src/cpp/runner/ModuleLoader.h"
#include "../../../../src/cpp/shared/utils.h"
#include "test_utils.h"
#include "ModuleTest.h"

class BaModuleTest : public ModuleTest {};

INSTANTIATE_TEST_CASE_P(Ba, BaModuleTest,
    ::testing::Values(
        "../../../../src/cpp/modules/manual/Manual.dll",
        "../../../../src/cpp/modules/manualEigen/ManualEigen.dll"
    ),
    get_module_name<ModuleTest::ParamType>);

TEST_P(BaModuleTest, Load)
{
    auto test = moduleLoader->get_ba_test();
    ASSERT_NE(test, nullptr);
}

//TODO: ObjectiveCalculationCorrectness test (module->calculateObjective(1);)
TEST_P(BaModuleTest, ObjectiveCalculationCorrectness)
{
    auto module = moduleLoader->get_ba_test();
    ASSERT_NE(module, nullptr);
    BAInput input;

    // Read instance
    read_ba_instance("batest.txt", input.n, input.m, input.p,
        input.cams, input.X, input.w, input.obs, input.feats);
    module->prepare(std::move(input));
    module->calculateObjective(1);

    auto output = module->output();
}

TEST_P(BaModuleTest, JacobianCalculationCorrectness)
{
    auto module = moduleLoader->get_ba_test();
    ASSERT_NE(module, nullptr);
    BAInput input;

    // Read instance
    read_ba_instance("batest.txt", input.n, input.m, input.p,
        input.cams, input.X, input.w, input.obs, input.feats);
    module->prepare(std::move(input));
    module->calculateJacobian(1);

    auto output = module->output();
    EXPECT_EQ(30, output.J.nrows);
    EXPECT_EQ(62, output.J.ncols);
    EXPECT_EQ(31, output.J.rows.size());
    EXPECT_EQ(310, output.J.cols.size());
    EXPECT_EQ(310, output.J.vals.size());
    EXPECT_NEAR(228.877, output.J.vals[0], 0.001);
    EXPECT_NEAR(634.575, output.J.vals[1], 0.001);
    EXPECT_NEAR(-782.223, output.J.vals[2], 0.001);
    EXPECT_NEAR(2.42893, output.J.vals[3], 0.00001);
    EXPECT_NEAR(-11.7828, output.J.vals[4], 0.0001);
    EXPECT_NEAR(2.54169, output.J.vals[5], 0.00001);
    EXPECT_NEAR(-1.03657, output.J.vals[6], 0.00001);
    EXPECT_NEAR(0.417022, output.J.vals[7], 0.000001);
    EXPECT_NEAR(0., output.J.vals[8], 0.000001);
    EXPECT_NEAR(-350.74, output.J.vals[9], 0.001);
    EXPECT_NEAR(-912.108, output.J.vals[10], 0.001);
    EXPECT_NEAR(-2.42893, output.J.vals[11], 0.00001);
    EXPECT_NEAR(11.7828, output.J.vals[12], 0.0001);
    EXPECT_NEAR(-0.834044, output.J.vals[307], 0.000001);
    EXPECT_NEAR(-0.834044, output.J.vals[308], 0.000001);
    EXPECT_NEAR(-0.834044, output.J.vals[309], 0.000001);
}

TEST_P(BaModuleTest, ObjectiveRunsMultipleTimes)
{
    auto module = moduleLoader->get_ba_test();
    ASSERT_NE(module, nullptr);
    BAInput input;

    // Read instance
    read_ba_instance("batest.txt", input.n, input.m, input.p,
        input.cams, input.X, input.w, input.obs, input.feats);
    module->prepare(std::move(input));

    EXPECT_TRUE(can_objective_run_multiple_times(*module, &ITest<BAInput, BAOutput>::calculateObjective));
}

TEST_P(BaModuleTest, JacobianRunsMultipleTimes)
{
    auto module = moduleLoader->get_ba_test();
    ASSERT_NE(module, nullptr);
    BAInput input;

    // Read instance
    read_ba_instance("batest.txt", input.n, input.m, input.p,
        input.cams, input.X, input.w, input.obs, input.feats);
    module->prepare(std::move(input));

    EXPECT_TRUE(can_objective_run_multiple_times(*module, &ITest<BAInput, BAOutput>::calculateJacobian));
}