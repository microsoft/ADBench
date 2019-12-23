// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#include <gtest/gtest.h>
#include "../../../../src/cpp/runner/ModuleLoader.h"
#include "../../../../src/cpp/shared/utils.h"
#include "test_utils.h"
#include "ModuleTest.h"

class HandModuleTest : public ModuleTest
{
protected:
    void simple_objective_calculation_correctness(int n_run_times);
    void simple_jacobian_calculation_correctness(int n_run_times);

    void complicated_objective_calculation_correctness(int n_run_times);
    void complicated_jacobian_calculation_correctness(int n_run_times);
};

void HandModuleTest::simple_objective_calculation_correctness(int n_run_times)
{
    SCOPED_TRACE("simple_objective_calculation_correctness");
    auto module = moduleLoader->get_hand_test();
    ASSERT_NE(module, nullptr);
    HandInput input;

    // Read instance
    read_hand_instance("model/", "handtestsmall.txt", &input.theta, &input.data);
    module->prepare(std::move(input));
    module->calculate_objective(n_run_times);

    auto output = module->output();

    EXPECT_NEAR(1.65193147941611551e-01, output.objective[0], epsilon);
    EXPECT_NEAR(-1.74542769272742593e-01, output.objective[1], epsilon);
    EXPECT_NEAR(1.54751161622253441e-01, output.objective[2], epsilon);
    EXPECT_NEAR(-1.25651749731793605e-01, output.objective[3], epsilon);
    EXPECT_NEAR(-4.25102935355075040e-02, output.objective[4], epsilon);
    EXPECT_NEAR(-1.30665781132340175e-01, output.objective[5], epsilon);
}

void HandModuleTest::simple_jacobian_calculation_correctness(int n_run_times)
{
    SCOPED_TRACE("simple_jacobian_calculation_correctness");
    auto module = moduleLoader->get_hand_test();
    ASSERT_NE(module, nullptr);
    HandInput input;

    // Read instance
    read_hand_instance("model/", "handtestsmall.txt", &input.theta, &input.data);
    module->prepare(std::move(input));
    module->calculate_jacobian(n_run_times);

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
        EXPECT_NEAR(expectedJ[i], output.jacobian[i], epsilon);
}

void HandModuleTest::complicated_objective_calculation_correctness(int n_run_times)
{
    SCOPED_TRACE("complicated_objective_calculation_correctness");
    auto module = moduleLoader->get_hand_test();
    ASSERT_NE(module, nullptr);
    HandInput input;

    // Read instance
    read_hand_instance("model/", "handtestcomplicated.txt", &input.theta, &input.data, &input.us);
    module->prepare(std::move(input));
    module->calculate_objective(n_run_times);

    auto output = module->output();

    EXPECT_NEAR(0.15618766169646370, output.objective[0], epsilon);
    EXPECT_NEAR(-0.14930052600332222, output.objective[1], epsilon);
    EXPECT_NEAR(0.17223808982645483, output.objective[2], epsilon);
    EXPECT_NEAR(-0.098877045184959655, output.objective[3], epsilon);
    EXPECT_NEAR(-0.016123803546210125, output.objective[4], epsilon);
    EXPECT_NEAR(-0.19758676846557965, output.objective[5], epsilon);
}

void HandModuleTest::complicated_jacobian_calculation_correctness(int n_run_times)
{
    SCOPED_TRACE("complicated_jacobian_calculation_correctness");
    auto module = moduleLoader->get_hand_test();
    ASSERT_NE(module, nullptr);
    HandInput input;

    // Read instance
    read_hand_instance("model/", "handtestcomplicated.txt", &input.theta, &input.data, &input.us);
    module->prepare(std::move(input));
    module->calculate_jacobian(n_run_times);

    auto output = module->output();

    std::vector<double> expectedJ
    {
        3.19994705650605837e-03,-5.83664316352128232e-03,5.26539698350125818e-03,6.09513107611836524e-03,-1.30273083127474543e-02,-1.97054905573765815e-02,
        5.94121036324768426e-03,-2.25087272196717869e-02,-7.98030902470658887e-04,4.72340259356063275e-03,5.73648537699011918e-03,8.52371287096032049e-03,
        -3.16780414139280486e-02,-1.17603133455238852e-02,-4.00357012848860105e-02,-2.21424420388885296e-02,-9.03798668988376082e-03,1.63019777955282150e-03,
        2.51273846313546725e-02,-6.73431005210687033e-03,4.48594779455911905e-02,3.97751453573731983e-02,-1.01785098875940283e-02,7.14646422504415374e-02,
        -3.43751692490045363e-02,-7.93824304538508912e-02,1.08995867664168408e-02,-8.70476400071599210e-02,-4.37081649532052238e-02,2.94403102374449152e-02,
        -1.,0.,0.,-1.,0.,0.,
        0.,-1.,0.,0.,-1.,0.,
        0.,0.,-1.,0.,0.,-1.,
        0.,0.,0.,-3.33849263402929107e-03,9.53458231126915585e-04,3.24947244952083786e-03,
        0.,0.,0.,1.28209220660817119e-03,4.01972269593312698e-03,8.49942589390221431e-04,
        0.,0.,0.,0.,0.,0.,
        0.,0.,0.,0.,0.,0.,
        0.,0.,0.,1.37205123955743335e-03,-9.33621518070085026e-04,-5.87537490240527642e-03,
        0.,0.,0.,-5.45177232375653083e-03,-1.38222424349224984e-03,2.95494237613404438e-03,
        0.,0.,0.,0.,0.,0.,
        0.,0.,0.,0.,0.,0.,
        0.,0.,0.,0.,0.,0.,
        0.,0.,0.,0.,0.,0.,
        0.,0.,0.,0.,0.,0.,
        0.,0.,0.,0.,0.,0.,
        0.,0.,0.,0.,0.,0.,
        0.,0.,0.,0.,0.,0.,
        0.,0.,0.,0.,0.,0.,
        0.,0.,0.,0.,0.,0.,
        -2.67300459304900973e-03,2.51903206295353913e-03,-1.65741767881614870e-03,0.,0.,0.,
        -2.05375964421033422e-04,6.35746365607068199e-03,2.11520284492772506e-03,0.,0.,0.,
        0.,0.,0.,0.,0.,0.,
        0.,0.,0.,0.,0.,0.,
    }; // Col-major

    ASSERT_EQ(expectedJ.size(), output.jacobian.size());
    EXPECT_EQ(expectedJ.size(), output.jacobian_ncols * output.jacobian_nrows);
    EXPECT_EQ(6, output.jacobian_nrows);
    EXPECT_EQ(28, output.jacobian_ncols);
    for (int i = 0; i < expectedJ.size(); ++i)
        EXPECT_NEAR(expectedJ[i], output.jacobian[i], epsilon);
}



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
    simple_objective_calculation_correctness(1);
}

TEST_P(HandModuleTest, SimpleObjectiveMultipleTimesCalculationCorrectness)
{
    simple_objective_calculation_correctness(3);
}

TEST_P(HandModuleTest, SimpleJacobianCalculationCorrectness)
{
    simple_jacobian_calculation_correctness(1);
}

TEST_P(HandModuleTest, SimpleJacobianMultipleTimesCalculationCorrectness)
{
    simple_jacobian_calculation_correctness(3);
}

TEST_P(HandModuleTest, ComplicatedObjectiveCalculationCorrectness)
{
    complicated_objective_calculation_correctness(1);
}

TEST_P(HandModuleTest, ComplicatedObjectiveMultipleTimesCalculationCorrectness)
{
    complicated_objective_calculation_correctness(3);
}

TEST_P(HandModuleTest, ComplicatedJacobianCalculationCorrectness)
{
    complicated_jacobian_calculation_correctness(1);
}

TEST_P(HandModuleTest, ComplicatedJacobianMultipleTimesCalculationCorrectness)
{
    complicated_jacobian_calculation_correctness(3);
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