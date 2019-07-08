#include <gtest/gtest.h>
#include "../../../../src/cpp/runner/ModuleLoader.h"
#include "../../../../src/cpp/shared/utils.h"

TEST(ManualTests, Lstm_Load) {
#ifdef _DEBUG
    ModuleLoader moduleLoader("../../../../src/cpp/modules/manual/Manuald.dll");
#else
    ModuleLoader moduleLoader("../../../../src/cpp/modules/manual/Manual.dll");
#endif
    auto test = moduleLoader.get_lstm_test();
    ASSERT_NE(test, nullptr);
}

TEST(ManualTests, Lstm_TestProcess)
{
#ifdef _DEBUG
    ModuleLoader moduleLoader("../../../../src/cpp/modules/manual/Manuald.dll");
#else
    ModuleLoader moduleLoader("../../../../src/cpp/modules/manual/Manual.dll");
#endif
    auto module = moduleLoader.get_lstm_test();
    ASSERT_NE(module, nullptr);
    LSTMInput input;

    // Read instance
    read_lstm_instance("lstmtest.txt", &input.l, &input.c, &input.b,
        input.main_params, input.extra_params, input.state, input.sequence);
    module->prepare(std::move(input));
    module->calculateObjective(1);
    auto output = module->output();
    EXPECT_NEAR(0.66666518, output.objective, 0.000001);
}