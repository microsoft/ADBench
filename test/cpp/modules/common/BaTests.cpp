#include <gtest/gtest.h>
#include "../../../../src/cpp/runner/ModuleLoader.h"
#include "../../../../src/cpp/shared/utils.h"
#include "test_utils.h"
#include "ModuleTest.h"

class BaModuleTest : public ModuleTest {};

INSTANTIATE_TEST_CASE_P(Ba, BaModuleTest,
    ::testing::Values(
        "../../../../src/cpp/modules/manual/Manual.dll",
        "../../../../src/cpp/modules/manualEigen/ManualEigen.dll",
        "../../../../src/cpp/modules/finite/Finite.dll",
        "../../../../src/cpp/modules/tapenade/Tapenade.dll"
    ),
    get_module_name<ModuleTest::ParamType>);

TEST_P(BaModuleTest, Load)
{
    auto test = moduleLoader->get_ba_test();
    ASSERT_NE(test, nullptr);
}

const double epsilon = 1e-06;

TEST_P(BaModuleTest, ObjectiveCalculationCorrectness)
{
    auto module = moduleLoader->get_ba_test();
    ASSERT_NE(module, nullptr);
    BAInput input;

    // Read instance
    read_ba_instance("batest.txt", input.n, input.m, input.p,
        input.cams, input.X, input.w, input.obs, input.feats);
    module->prepare(std::move(input));
    module->calculate_objective(1);

    auto output = module->output();
    for (int i = 0; i < 20; i += 2)
    {
        EXPECT_NEAR(-2.69048849235189402e-01, output.reproj_err[i], epsilon);
        EXPECT_NEAR(2.59944792677901881e-01, output.reproj_err[i + 1], epsilon);
    }
    for (int i = 0; i < 10; i++)
    {
        EXPECT_NEAR(8.26092651515999976e-01, output.w_err[i], epsilon);
    }
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
    module->calculate_jacobian(1);

    auto output = module->output();
    EXPECT_EQ(30, output.J.nrows);
    EXPECT_EQ(62, output.J.ncols);
    EXPECT_EQ(31, output.J.rows.size());
    EXPECT_EQ(310, output.J.cols.size());
    EXPECT_EQ(310, output.J.vals.size());
    EXPECT_NEAR(2.28877202208246757e+02, output.J.vals[0], epsilon);
    EXPECT_NEAR(6.34574811495545418e+02, output.J.vals[1], epsilon);
    EXPECT_NEAR(-7.82222866259340549e+02, output.J.vals[2], epsilon);
    EXPECT_NEAR(2.42892615607159668e+00, output.J.vals[3], epsilon);
    EXPECT_NEAR(-1.17828079628011313e+01, output.J.vals[4], epsilon);
    EXPECT_NEAR(2.54169312487743460e+00, output.J.vals[5], epsilon);
    EXPECT_NEAR(-1.03657084958518086e+00, output.J.vals[6], epsilon);
    EXPECT_NEAR(4.17022000000000004e-01, output.J.vals[7], epsilon);
    EXPECT_NEAR(0., output.J.vals[8], epsilon);
    EXPECT_NEAR(-3.50739521096005205e+02, output.J.vals[9], epsilon);
    EXPECT_NEAR(-9.12107773668008576e+02, output.J.vals[10], epsilon);
    EXPECT_NEAR(-2.42892615607159668e+00, output.J.vals[11], epsilon);
    EXPECT_NEAR(1.17828079628011313e+01, output.J.vals[12], epsilon);
    EXPECT_NEAR(-8.34044000000000008e-01, output.J.vals[307], epsilon);
    EXPECT_NEAR(-8.34044000000000008e-01, output.J.vals[308], epsilon);
    EXPECT_NEAR(-8.34044000000000008e-01, output.J.vals[309], epsilon);
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

    EXPECT_TRUE(can_objective_run_multiple_times(*module, &ITest<BAInput, BAOutput>::calculate_objective));
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

    EXPECT_TRUE(can_objective_run_multiple_times(*module, &ITest<BAInput, BAOutput>::calculate_jacobian));
}