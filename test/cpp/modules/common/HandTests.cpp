#include <gtest/gtest.h>
#include "../../../../src/cpp/runner/ModuleLoader.h"
#include "../../../../src/cpp/shared/utils.h"
#include "test_utils.h"
#include "ModuleTest.h"

class HandModuleTest : public ModuleTest {};

INSTANTIATE_TEST_CASE_P(Hand, HandModuleTest,
    ::testing::Values(
        std::make_tuple("../../../../src/cpp/modules/manual/Manual.dll", 1e-8),
        std::make_tuple("../../../../src/cpp/modules/manualEigen/ManualEigen.dll", 1e-8),
        std::make_tuple("../../../../src/cpp/modules/finite/Finite.dll", 1e-8),
        std::make_tuple("../../../../src/cpp/modules/finiteEigen/FiniteEigen.dll", 1e-8),
        std::make_tuple("../../../../src/cpp/modules/tapenade/Tapenade.dll", 1e-8)
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
    module->calculate_objective(1);

    auto output = module->output();

    EXPECT_NEAR(1.65193147941611551e-01, output.objective[0], epsilon);
    EXPECT_NEAR(-1.74542769272742593e-01, output.objective[1], epsilon);
    EXPECT_NEAR(1.54751161622253441e-01, output.objective[2], epsilon);
    EXPECT_NEAR(-1.25651749731793605e-01, output.objective[3], epsilon);
    EXPECT_NEAR(-4.25102935355075040e-02, output.objective[4], epsilon);
    EXPECT_NEAR(-1.30665781132340175e-01, output.objective[5], epsilon);
}

TEST_P(HandModuleTest, SimpleJacobianCalculationCorrectness)
{
    auto module = moduleLoader->get_hand_test();
    ASSERT_NE(module, nullptr);
    HandInput input;

    // Read instance
    read_hand_instance("model/", "handtestsmall.txt", &input.theta, &input.data);
    module->prepare(std::move(input));
    module->calculate_jacobian(1);

    auto output = module->output();

    std::vector<double> expectedJ
    {
        -1.95512959341282745e-02,-6.81027576369377941e-03,-4.09359630708754085e-02,-7.10032003143440671e-02,-2.81346929141111299e-02,-2.54484136783155838e-02,
        1.18421319736437044e-02, 1.74108797580776152e-03, 2.57836165362687400e-02, 5.14892578985870278e-02, -4.50591977492771356e-02, 6.23981738234076627e-02,
        -1.08140043450366714e-02, -6.54731655106268462e-02, 2.95529253068245066e-03, -6.33408854067304267e-02, -8.98189200086859235e-02, 2.07440902671436785e-02,
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
        0, 0, 0, -3.45326893768281365e-02, 2.42024596962444292e-02, -3.10675692993888850e-03,
        0, 0, 0, -1.95437595587887036e-02, -1.84392814127634017e-02, 6.52740542794425036e-03,
        0, 0, 0, -1.29102628630682510e-02, 9.76606245804552756e-03, 8.49553578389919579e-03,
        0, 0, 0, 1.99738182488361877e-03, -1.42570914120403679e-03, -4.35490319929073976e-04,
        -2.21537299179855318e-02, 1.42669175415592216e-02, -3.12350905279757118e-02, 0, 0, 0,
        2.98023294354714807e-02, 2.58519935565392558e-02, -9.40429974684049881e-03, 0, 0, 0,
        -8.89718384720838799e-03, 2.30412622537484605e-03, -1.84753145105870202e-02, 0, 0, 0,
        -2.24887887916698764e-03, 3.09895230315512067e-03, -3.09211880497457705e-04, 0, 0, 0
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
    module->calculate_objective(1);

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
    module->calculate_jacobian(1);

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

    EXPECT_TRUE(can_objective_run_multiple_times(*module, &ITest<HandInput, HandOutput>::calculate_objective));
}

TEST_P(HandModuleTest, SimpleJacobianRunsMultipleTimes)
{
    auto module = moduleLoader->get_hand_test();
    ASSERT_NE(module, nullptr);
    HandInput input;

    // Read instance
    read_hand_instance("model/", "handtestsmall.txt", &input.theta, &input.data);
    module->prepare(std::move(input));

    EXPECT_TRUE(can_objective_run_multiple_times(*module, &ITest<HandInput, HandOutput>::calculate_jacobian));
}

TEST_P(HandModuleTest, ComplicatedObjectiveRunsMultipleTimes)
{
    auto module = moduleLoader->get_hand_test();
    ASSERT_NE(module, nullptr);
    HandInput input;

    // Read instance
    read_hand_instance("model/", "handtestcomplicated.txt", &input.theta, &input.data, &input.us);
    module->prepare(std::move(input));

    EXPECT_TRUE(can_objective_run_multiple_times(*module, &ITest<HandInput, HandOutput>::calculate_objective));
}

TEST_P(HandModuleTest, ComplicatedJacobianRunsMultipleTimes)
{
    auto module = moduleLoader->get_hand_test();
    ASSERT_NE(module, nullptr);
    HandInput input;

    // Read instance
    read_hand_instance("model/", "handtestcomplicated.txt", &input.theta, &input.data, &input.us);
    module->prepare(std::move(input));

    EXPECT_TRUE(can_objective_run_multiple_times(*module, &ITest<HandInput, HandOutput>::calculate_jacobian));
}