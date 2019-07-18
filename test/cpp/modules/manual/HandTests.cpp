#include <gtest/gtest.h>
#include "../../../../src/cpp/runner/ModuleLoader.h"
#include "../../../../src/cpp/shared/utils.h"
#include "test_utils.h"
#include "ModuleTest.h"

class HandModuleTest : public ModuleTest {};

INSTANTIATE_TEST_CASE_P(Hand, HandModuleTest,
    ::testing::Values(
        "../../../../src/cpp/modules/manual/Manual.dll",
        "../../../../src/cpp/modules/manualEigen/ManualEigen.dll"
    ),
    get_module_name<ModuleTest::ParamType>);

TEST_P(HandModuleTest, Load)
{
    auto test = moduleLoader->get_hand_test();
    ASSERT_NE(test, nullptr);
}

TEST_P(HandModuleTest, SimpleObjectiveCalculationCorrectness)
{
    auto module = moduleLoader->get_hand_test();
    ASSERT_NE(module, nullptr);
    HandInput input;

    // Read instance
    read_hand_instance("model/", "handtestsmall.txt", &input.theta, &input.data);
    module->prepare(std::move(input));
    module->calculateObjective(1);

    auto output = module->output();

    EXPECT_NEAR(0.16519314794161155, output.objective[0], 0.0000000001);
    EXPECT_NEAR(-0.17454276927274259, output.objective[1], 0.0000000001);
    EXPECT_NEAR(0.15475116162225344, output.objective[2], 0.0000000001);
    EXPECT_NEAR(-0.12565174973179360, output.objective[3], 0.0000000001);
    EXPECT_NEAR(-0.042510293535507504, output.objective[4], 0.0000000001);
    EXPECT_NEAR(-0.13066578113234018, output.objective[5], 0.0000000001);

}

TEST_P(HandModuleTest, SimpleJacobianCalculationCorrectness)
{
    auto module = moduleLoader->get_hand_test();
    ASSERT_NE(module, nullptr);
    HandInput input;

    // Read instance
    read_hand_instance("model/", "handtestsmall.txt", &input.theta, &input.data);
    module->prepare(std::move(input));
    module->calculateJacobian(1);

    auto output = module->output();

    std::vector<double> expectedJ
    {
        -0.0195513, -0.00681028, -0.040936, -0.0710032, -0.0281347, -0.0254484,
        0.0118421, 0.00174109, 0.0257836, 0.0514893, -0.0450592, 0.0623982,
        -0.010814, -0.0654732, 0.00295529, -0.0633409, -0.0898189, 0.0207441,
        -1, 0, 0, -1, 0, 0,
        0, -1, 0, 0, -1, 0,
        0, 0, -1, 0, 0, -1,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, -0.0345327, 0.0242025, -0.00310676,
        0, 0, 0, -0.0195438, -0.0184393, 0.00652741,
        0, 0, 0, -0.0129103, 0.00976606, 0.00849554,
        0, 0, 0, 0.00199738, -0.00142571, -0.00043549,
        -0.0221537, 0.0142669, -0.0312351, 0, 0, 0,
        0.0298023, 0.025852, -0.0094043, 0, 0, 0,
        -0.00889718, 0.00230413, -0.0184753, 0, 0, 0,
        -0.00224888, 0.00309895, -0.000309212, 0, 0, 0
    }; // Col-major

    ASSERT_EQ(expectedJ.size(), output.jacobian.size());
    EXPECT_EQ(expectedJ.size(), output.jacobian_ncols * output.jacobian_nrows);
    EXPECT_EQ(6, output.jacobian_nrows);
    EXPECT_EQ(26, output.jacobian_ncols);
    for (int i = 0; i < expectedJ.size(); ++i)
        EXPECT_NEAR(expectedJ[i], output.jacobian[i], 0.000001);
}

TEST_P(HandModuleTest, ComplicatedObjectiveCalculationCorrectness)
{
    auto module = moduleLoader->get_hand_test();
    ASSERT_NE(module, nullptr);
    HandInput input;

    // Read instance
    read_hand_instance("model/", "handtestcomplicated.txt", &input.theta, &input.data, &input.us);
    module->prepare(std::move(input));
    module->calculateObjective(1);

    auto output = module->output();

    EXPECT_NEAR(0.15618766169646370, output.objective[0], 0.0000000001);
    EXPECT_NEAR(-0.14930052600332222, output.objective[1], 0.0000000001);
    EXPECT_NEAR(0.17223808982645483, output.objective[2], 0.0000000001);
    EXPECT_NEAR(-0.098877045184959655, output.objective[3], 0.0000000001);
    EXPECT_NEAR(-0.016123803546210125, output.objective[4], 0.0000000001);
    EXPECT_NEAR(-0.19758676846557965, output.objective[5], 0.0000000001);
}

TEST_P(HandModuleTest, ComplicatedJacobianCalculationCorrectness)
{
    auto module = moduleLoader->get_hand_test();
    ASSERT_NE(module, nullptr);
    HandInput input;

    // Read instance
    read_hand_instance("model/", "handtestcomplicated.txt", &input.theta, &input.data, &input.us);
    module->prepare(std::move(input));
    module->calculateJacobian(1);

    auto output = module->output();

    std::vector<double> expectedJ
    {
        0.00319995, -0.00583664, 0.0052654, 0.00609513, -0.0130273, -0.0197055,
        0.00594121, -0.0225087, -0.000798031, 0.0047234, 0.00573649, 0.00852371,
        -0.031678, -0.0117603, -0.0400357, -0.0221424, -0.00903799, 0.0016302,
        0.0251274, -0.00673431, 0.0448595, 0.0397751, -0.0101785, 0.0714646,
        -0.0343752, -0.0793824, 0.0108996, -0.0870476, -0.0437082, 0.0294403,
        -1, 0, 0, -1, 0, 0,
        0, -1, 0, 0, -1, 0,
        0, 0, -1, 0, 0, -1,
        0, 0, 0, -0.00333849, 0.000953458, 0.00324947,
        0, 0, 0, 0.00128209, 0.00401972, 0.000849943,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0.00137205, -0.000933622, -0.00587537,
        0, 0, 0, -0.00545177, -0.00138222, 0.00295494,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        -0.002673, 0.00251903, -0.00165742, 0, 0, 0,
        -0.000205376, 0.00635746, 0.0021152, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0
    }; // Col-major

    ASSERT_EQ(expectedJ.size(), output.jacobian.size());
    EXPECT_EQ(expectedJ.size(), output.jacobian_ncols * output.jacobian_nrows);
    EXPECT_EQ(6, output.jacobian_nrows);
    EXPECT_EQ(28, output.jacobian_ncols);
    for (int i = 0; i < expectedJ.size(); ++i)
        EXPECT_NEAR(expectedJ[i], output.jacobian[i], 0.000001);
}

TEST_P(HandModuleTest, SimpleObjectiveRunsMultipleTimes)
{
    auto module = moduleLoader->get_hand_test();
    ASSERT_NE(module, nullptr);
    HandInput input;

    // Read instance
    read_hand_instance("model/", "handtestsmall.txt", &input.theta, &input.data);
    module->prepare(std::move(input));

    EXPECT_TRUE(can_objective_run_multiple_times(*module, &ITest<HandInput, HandOutput>::calculateObjective));
}

TEST_P(HandModuleTest, SimpleJacobianRunsMultipleTimes)
{
    auto module = moduleLoader->get_hand_test();
    ASSERT_NE(module, nullptr);
    HandInput input;

    // Read instance
    read_hand_instance("model/", "handtestsmall.txt", &input.theta, &input.data);
    module->prepare(std::move(input));

    EXPECT_TRUE(can_objective_run_multiple_times(*module, &ITest<HandInput, HandOutput>::calculateJacobian));
}

TEST_P(HandModuleTest, ComplicatedObjectiveRunsMultipleTimes)
{
    auto module = moduleLoader->get_hand_test();
    ASSERT_NE(module, nullptr);
    HandInput input;

    // Read instance
    read_hand_instance("model/", "handtestcomplicated.txt", &input.theta, &input.data, &input.us);
    module->prepare(std::move(input));

    EXPECT_TRUE(can_objective_run_multiple_times(*module, &ITest<HandInput, HandOutput>::calculateObjective));
}

TEST_P(HandModuleTest, ComplicatedJacobianRunsMultipleTimes)
{
    auto module = moduleLoader->get_hand_test();
    ASSERT_NE(module, nullptr);
    HandInput input;

    // Read instance
    read_hand_instance("model/", "handtestcomplicated.txt", &input.theta, &input.data, &input.us);
    module->prepare(std::move(input));

    EXPECT_TRUE(can_objective_run_multiple_times(*module, &ITest<HandInput, HandOutput>::calculateJacobian));
}