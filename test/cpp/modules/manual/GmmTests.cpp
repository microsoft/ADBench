#include <gtest/gtest.h>
#include "../../../../src/cpp/runner/ModuleLoader.h"
#include "../../../../src/cpp/shared/utils.h"

namespace {

    using ::testing::TestWithParam;
    using ::testing::Values;

    class ModuleTest : public TestWithParam<const char*> {
    public:
        ~ModuleTest() override { delete moduleLoader; }
        void SetUp() override
        {
            moduleLoader = new ModuleLoader(GetParam());
        }
        void TearDown() override {
            delete moduleLoader;
            moduleLoader = nullptr;
        }
    protected:
        ModuleLoader* moduleLoader;
    };

    TEST_P(ModuleTest, Load)
    {
        auto module = moduleLoader->get_gmm_test();
        ASSERT_NE(module, nullptr);
    }

    TEST_P(ModuleTest, TestProcess)
    {
        auto module = moduleLoader->get_gmm_test();
        ASSERT_NE(module, nullptr);
        GMMInput input;

        // Read instance
        read_gmm_instance("gmmtest.txt", &input.d, &input.k, &input.n,
            input.alphas, input.means, input.icf, input.x, input.wishart, false);
        module->prepare(std::move(input));
        module->calculateObjective(1);
        module->calculateJacobian(1);
        auto output = module->output();
        EXPECT_NEAR(8.0738, output.objective, 0.00001);
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

    INSTANTIATE_TEST_CASE_P(Gmm, ModuleTest,
        ::testing::Values(
            "../../../../src/cpp/modules/manual/Manual.dll",
            "../../../../src/cpp/modules/manualEigen/ManualEigen.dll"
        ));

}  // namespace