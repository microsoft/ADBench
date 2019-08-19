#include <gtest/gtest.h>
#include "../../../../src/cpp/runner/ModuleLoader.h"
#include "../../../../src/cpp/shared/utils.h"
#include "test_utils.h"
#include "ModuleTest.h"

class GmmModuleTest : public ModuleTest {};

INSTANTIATE_TEST_CASE_P(Gmm, GmmModuleTest,
    ::testing::Values(
        "../../../../src/cpp/modules/manual/Manual.dll",
        "../../../../src/cpp/modules/manualEigen/ManualEigen.dll",
        "../../../../src/cpp/modules/finite/Finite.dll",
        "../../../../src/cpp/modules/manualEigenVector/ManualEigenVector.dll",
        "../../../../src/cpp/modules/tapenade/Tapenade.dll"
    ),
    get_module_name<ModuleTest::ParamType>);

TEST_P(GmmModuleTest, Load)
{
    auto module = moduleLoader->get_gmm_test();
    ASSERT_NE(module, nullptr);
}

TEST_P(GmmModuleTest, ObjectiveCalculationCorrectness)
{
    auto module = moduleLoader->get_gmm_test();
    ASSERT_NE(module, nullptr);
    GMMInput input;

    // Read instance
    read_gmm_instance("gmmtest.txt", &input.d, &input.k, &input.n,
        input.alphas, input.means, input.icf, input.x, input.wishart, false);
    module->prepare(std::move(input));
    module->calculate_objective(1);

    auto output = module->output();
    EXPECT_NEAR(8.0738, output.objective, 0.00001);
}

TEST_P(GmmModuleTest, JacobianCalculationCorrectness)
{
    auto module = moduleLoader->get_gmm_test();
    ASSERT_NE(module, nullptr);
    GMMInput input;

    // Read instance
    read_gmm_instance("gmmtest.txt", &input.d, &input.k, &input.n,
        input.alphas, input.means, input.icf, input.x, input.wishart, false);
    module->prepare(std::move(input));
    module->calculate_jacobian(1);

    auto output = module->output();
    EXPECT_EQ(18, output.gradient.size());
    EXPECT_NEAR(0.108663, output.gradient[0], 0.00001);
    EXPECT_NEAR(-0.74127, output.gradient[1], 0.00001);
    EXPECT_NEAR(0.632607, output.gradient[2], 0.00001);
    EXPECT_NEAR(1.116926, output.gradient[3], 0.00001);
    EXPECT_NEAR(0.163333, output.gradient[4], 0.00001);
    EXPECT_NEAR(-0.022, output.gradient[5], 0.00001);
    EXPECT_NEAR(0.227778, output.gradient[6], 0.00001);
    EXPECT_NEAR(1.20963, output.gradient[7], 0.00001);
    EXPECT_NEAR(-0.06064, output.gradient[8], 0.00001);
    EXPECT_NEAR(2.5853, output.gradient[9], 0.00001);
    EXPECT_NEAR(0.11263, output.gradient[10], 0.00001);
    EXPECT_NEAR(0.38574, output.gradient[11], 0.00001);
    EXPECT_NEAR(0.07352, output.gradient[12], 0.00001);
    EXPECT_NEAR(5.41836, output.gradient[13], 0.00001);
    EXPECT_NEAR(-0.3215, output.gradient[14], 0.00001);
    EXPECT_NEAR(1.71892, output.gradient[15], 0.00001);
    EXPECT_NEAR(0.86009, output.gradient[16], 0.00001);
    EXPECT_NEAR(-0.99464, output.gradient[17], 0.00001);
}

TEST_P(GmmModuleTest, ObjectiveRunsMultipleTimes)
{
    auto module = moduleLoader->get_gmm_test();
    ASSERT_NE(module, nullptr);
    GMMInput input;

    // Read instance
    read_gmm_instance("gmmtest.txt", &input.d, &input.k, &input.n,
        input.alphas, input.means, input.icf, input.x, input.wishart, false);
    module->prepare(std::move(input));

    EXPECT_TRUE(can_objective_run_multiple_times(*module, &ITest<GMMInput, GMMOutput>::calculate_objective));
}

TEST_P(GmmModuleTest, JacobianRunsMultipleTimes)
{
    auto module = moduleLoader->get_gmm_test();
    ASSERT_NE(module, nullptr);
    GMMInput input;

    // Read instance
    read_gmm_instance("gmmtest.txt", &input.d, &input.k, &input.n,
        input.alphas, input.means, input.icf, input.x, input.wishart, false);
    module->prepare(std::move(input));

    EXPECT_TRUE(can_objective_run_multiple_times(*module, &ITest<GMMInput, GMMOutput>::calculate_jacobian));
}