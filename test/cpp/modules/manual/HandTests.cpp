#include <gtest/gtest.h>
#include "../../../../src/cpp/runner/ModuleLoader.h"
#include "../../../../src/cpp/shared/utils.h"

TEST(HandTests, Load) {
#ifdef _DEBUG
    ModuleLoader moduleLoader("../../../../src/cpp/modules/manual/Manuald.dll");
#else
    ModuleLoader moduleLoader("../../../../src/cpp/modules/manual/Manual.dll");
#endif
    auto test = moduleLoader.get_hand_test();
    ASSERT_NE(test, nullptr);
}

TEST(HandTests, TestProcessSimple)
{
#ifdef _DEBUG
    ModuleLoader moduleLoader("../../../../src/cpp/modules/manual/Manuald.dll");
#else
    ModuleLoader moduleLoader("../../../../src/cpp/modules/manual/Manual.dll");
#endif
    auto module = moduleLoader.get_hand_test();
    ASSERT_NE(module, nullptr);
    HandInput input;

    // Read instance
    read_hand_instance("model/", "handtestsmall.txt", &input.theta, &input.data);
    module->prepare(std::move(input));
    module->calculateObjective(1);
    module->calculateJacobian(1);

    auto output = module->output();
    
    EXPECT_EQ(6 * 26, output.jacobian.size());
    EXPECT_NEAR(-0.0195513, output.jacobian[0], 0.000001);
    EXPECT_NEAR(-0.00681028, output.jacobian[1], 0.000001);
    EXPECT_NEAR(-0.040936, output.jacobian[2], 0.000001);
    EXPECT_NEAR(0., output.jacobian[6 * 26 - 3], 0.000001);
    EXPECT_NEAR(0., output.jacobian[6 * 26 - 2], 0.000001);
    EXPECT_NEAR(0., output.jacobian[6 * 26 - 1], 0.000001);
}