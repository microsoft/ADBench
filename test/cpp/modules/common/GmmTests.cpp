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

const double epsilon = 1e-08;

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
    EXPECT_NEAR(8.07380408004975791e+00, output.objective, 0.00001);
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
    EXPECT_NEAR(1.08662855508652456e-01, output.gradient[0], epsilon);
    EXPECT_NEAR(-7.41270039523898472e-01, output.gradient[1], epsilon);
    EXPECT_NEAR(6.32607184015246071e-01, output.gradient[2], epsilon);
    EXPECT_NEAR(1.11692576532787013e+00, output.gradient[3], epsilon);
    EXPECT_NEAR(1.63333013551455269e-01, output.gradient[4], epsilon);
    EXPECT_NEAR(-2.19989824071193142e-02, output.gradient[5], epsilon);
    EXPECT_NEAR(2.27778292254236098e-01, output.gradient[6], epsilon);
    EXPECT_NEAR(1.20963025612832187e+00, output.gradient[7], epsilon);
    EXPECT_NEAR(-6.06375920733956339e-02, output.gradient[8], epsilon);
    EXPECT_NEAR(2.58529994051162237e+00, output.gradient[9], epsilon);
    EXPECT_NEAR(1.12632694524213789e-01, output.gradient[10], epsilon);
    EXPECT_NEAR(3.85744309849611777e-01, output.gradient[11], epsilon);
    EXPECT_NEAR(7.35180573182305508e-02, output.gradient[12], epsilon);
    EXPECT_NEAR(5.41836362715595232e+00, output.gradient[13], epsilon);
    EXPECT_NEAR(-3.21494409677446469e-01, output.gradient[14], epsilon);
    EXPECT_NEAR(1.71892309775004937e+00, output.gradient[15], epsilon);
    EXPECT_NEAR(8.60091090790866875e-01, output.gradient[16], epsilon);
    EXPECT_NEAR(-9.94640930466322848e-01, output.gradient[17], epsilon);
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