// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#include <gtest/gtest.h>
#include "../../../../src/cpp/runner/ModuleLoader.h"
#include "../../../../src/cpp/shared/utils.h"
#include "test_utils.h"
#include "ModuleTest.h"

class GmmModuleTest : public ModuleTest
{
protected:
    void objective_calculation_correctness(int n_run_times);
    void jacobian_calculation_correctness(int n_run_times);
};

void GmmModuleTest::objective_calculation_correctness(int n_run_times)
{
    SCOPED_TRACE("objective_calculation_correctness");
    auto module = moduleLoader->get_gmm_test();
    ASSERT_NE(module, nullptr);
    GMMInput input;

    // Read instance
    read_gmm_instance("gmmtest.txt", &input.d, &input.k, &input.n,
        input.alphas, input.means, input.icf, input.x, input.wishart, false);
    module->prepare(std::move(input));
    module->calculate_objective(n_run_times);

    auto output = module->output();
    EXPECT_NEAR(8.07380408004975791e+00, output.objective, epsilon);
}

void GmmModuleTest::jacobian_calculation_correctness(int n_run_times)
{
    SCOPED_TRACE("jacobian_calculation_correctness");
    auto module = moduleLoader->get_gmm_test();
    ASSERT_NE(module, nullptr);
    GMMInput input;

    // Read instance
    read_gmm_instance("gmmtest.txt", &input.d, &input.k, &input.n,
        input.alphas, input.means, input.icf, input.x, input.wishart, false);
    module->prepare(std::move(input));
    module->calculate_jacobian(n_run_times);

    auto output = module->output();

    std::vector<double> expected_gradient { 1.08662855508652456e-01, -7.41270039523898472e-01, 6.32607184015246071e-01, 1.11692576532787013e+00, 1.63333013551455269e-01, -2.19989824071193142e-02, 2.27778292254236098e-01, 1.20963025612832187e+00, -6.06375920733956339e-02, 2.58529994051162237e+00, 1.12632694524213789e-01, 3.85744309849611777e-01, 7.35180573182305508e-02, 5.41836362715595232e+00, -3.21494409677446469e-01, 1.71892309775004937e+00, 8.60091090790866875e-01, -9.94640930466322848e-01 };
    EXPECT_EQ(18, output.gradient.size());
    
    for (int i = 0; i < expected_gradient.size(); i++)
        EXPECT_NEAR(expected_gradient[i], output.gradient[i], epsilon);
}



INSTANTIATE_TEST_CASE_P(Gmm, GmmModuleTest,
    ::testing::Values(
        std::make_tuple("../../../../src/cpp/modules/manual/Manual.dll", 1e-8),
        std::make_tuple("../../../../src/cpp/modules/manualEigen/ManualEigen.dll", 1e-8),
        std::make_tuple("../../../../src/cpp/modules/finite/Finite.dll", 1e-8),
        std::make_tuple("../../../../src/cpp/modules/manualEigenVector/ManualEigenVector.dll", 1e-8),
        std::make_tuple("../../../../src/cpp/modules/tapenade/Tapenade.dll", 1e-8)
    ),
    get_module_name<ModuleTest::ParamType>);

TEST_P(GmmModuleTest, Load)
{
    auto module = moduleLoader->get_gmm_test();
    ASSERT_NE(module, nullptr);
}

TEST_P(GmmModuleTest, ObjectiveCalculationCorrectness)
{
    objective_calculation_correctness(1);
}

TEST_P(GmmModuleTest, ObjectiveMultipleTimesCalculationCorrectness)
{
    objective_calculation_correctness(3);
}

TEST_P(GmmModuleTest, JacobianCalculationCorrectness)
{
    jacobian_calculation_correctness(1);
}

TEST_P(GmmModuleTest, JacobianMultipleTimesCalculationCorrectness)
{
    jacobian_calculation_correctness(3);
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