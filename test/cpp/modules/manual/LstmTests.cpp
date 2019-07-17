#include <gtest/gtest.h>
#include "../../../../src/cpp/runner/ModuleLoader.h"
#include "../../../../src/cpp/shared/utils.h"
#include "test_utils.h"
#include "ModuleTest.h"

class LstmModuleTest : public ModuleTest {};

INSTANTIATE_TEST_CASE_P(Lstm, LstmModuleTest,
    ::testing::Values(
        "../../../../src/cpp/modules/manual/Manual.dll"
    ),
    get_module_name<ModuleTest::ParamType>);

TEST_P(LstmModuleTest, Load) {
    auto test = moduleLoader->get_lstm_test();
    ASSERT_NE(test, nullptr);
}

//TODO: Objective & Jacobian CalculationCorrectness test

TEST_P(LstmModuleTest, TestProcess)
{
    auto module = moduleLoader->get_lstm_test();
    ASSERT_NE(module, nullptr);
    LSTMInput input;

    // Read instance
    read_lstm_instance("lstmtest.txt", &input.l, &input.c, &input.b,
        input.main_params, input.extra_params, input.state, input.sequence);
    module->prepare(std::move(input));
    module->calculateObjective(1);
    module->calculateJacobian(1);

    auto output = module->output();
    EXPECT_NEAR(0.66666518, output.objective, 0.000001);

    std::vector<double> expectedGradient
    {
        0.000003, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, -0.000037, -0.000155, 0.000005, -0.000004, -0.000001, -0.000002, -0.000001, 0.000125, 0.000005, 0.000003, 0.000028, 0.000045, 0.000040, 0.000011, -0.000074, -0.000392, 0.000006, -0.000025, -0.000005, -0.000005, -0.000001, 0.000004, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, -0.000062, -0.000214, 0.000006, -0.000005, -0.000002, -0.000005, -0.000003, 0.000850, 0.000214, 0.000127, 0.000103, 0.000033, 0.000147, 0.000020, -0.000171, -0.000997, 0.000106, -0.000041, -0.000005, -0.000006, -0.000002, 0.000742, 0.000136, 0.000092, 0.000114, 0.000131, 0.000190, 0.000067, -0.000300, -0.001394, 0.000078, -0.000071, -0.000016, -0.000016, -0.000006, 0.000365, 0.000108, 0.000068, 0.000051, 0.000069, 0.000097, 0.000024, -0.000132, -0.000737, 0.000045, -0.000045, -0.000008, -0.000008, -0.000002, 0.000801, 0.000081, 0.000070, 0.000135, 0.000207, 0.000294, 0.000208, -0.000501, -0.001904, 0.000068, -0.000089, -0.000040, -0.000032, -0.000025, 0.002478, 0.005075, 0.002539, 0.000188, 0.000051, 0.000354, 0.000043, -0.000307, -0.001873, 0.000787, -0.000074, -0.000007, -0.000010, -0.000003, 0.000539, 0.000041, 0.000065, 0.000377, 0.001001, 0.000230, 0.000445, -0.000974, -0.004512, 0.000142, -0.000017, -0.000023, -0.000069, -0.000282, 0.000254, 0.000292, 0.000288, 0.000066, 0.000612, 0.000108, 0.000099, -0.000540, -0.001953, 0.000287, -0.000006, -0.000007, -0.000036, -0.000142, 0.000990, 0.000067, 0.000096, 0.000284, 0.001414, 0.000743, 0.000163, -0.001809, -0.005789, 0.000109, -0.000282, -0.000158, -0.000162, -0.000444, 0.001238, 0.000371, 0.000896, 0.000955, 0.000794, 0.000133, 0.001910, -0.001277, -0.007988, 0.001318, -0.000012, -0.000012, -0.000057, -0.000176, 0.001571, 0.000964, 0.001297, 0.000685, 0.001561, 0.000552, 0.000945, -0.001746, -0.008473, 0.001061, -0.000030, -0.000036, -0.000117, -0.000454, 0.000484, 0.000537, 0.000710, 0.000403, 0.000921, 0.000184, 0.000585, -0.000912, -0.003719, 0.000524, -0.000009, -0.000009, -0.000062, -0.000260, 0.002886, 0.001569, 0.001929, 0.000516, 0.002204, 0.001783, 0.000347, -0.003243, -0.010870, 0.000814, -0.000509, -0.000250, -0.000274, -0.000716, 0.002362, 0.000682, 0.002212, 0.005815, 0.001197, 0.000226, 0.011221, -0.002159, -0.015211, 0.002407, -0.000016, -0.000016, -0.000099, -0.000323, 0.000009, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, -0.000174, -0.000322, 0.000008, -0.000030, -0.000011, -0.000003, -0.000002, 0.011404, 0.009939, 0.004539, 0.001468, 0.015958, 0.007132, 0.002521, -0.017999, -0.026266, 0.002443, -0.003671, -0.013144, -0.004550, -0.010927, 0.021735, 0.018286, 0.011189, 0.008977, 0.023985, 0.012080, 0.014864, -0.030232, -0.050012, 0.004466, -0.005236, -0.017932, -0.007732, -0.020023
    }; // produced by PyTorch

    ASSERT_EQ(expectedGradient.size(), output.gradient.size());
    for (int i = 0; i < expectedGradient.size(); ++i)
        EXPECT_NEAR(expectedGradient[i], output.gradient[i], 0.000001);
}

TEST_P(LstmModuleTest, ObjectiveRunsMultipleTimes)
{
    auto module = moduleLoader->get_lstm_test();
    ASSERT_NE(module, nullptr);
    LSTMInput input;

    // Read instance
    read_lstm_instance("lstmtest.txt", &input.l, &input.c, &input.b,
        input.main_params, input.extra_params, input.state, input.sequence);
    module->prepare(std::move(input));

    EXPECT_TRUE(can_objective_run_multiple_times(*module, &ITest<LSTMInput, LSTMOutput>::calculateObjective));
}

TEST_P(LstmModuleTest, JacobianRunsMultipleTimes)
{
    auto module = moduleLoader->get_lstm_test();
    ASSERT_NE(module, nullptr);
    LSTMInput input;

    // Read instance
    read_lstm_instance("lstmtest.txt", &input.l, &input.c, &input.b,
        input.main_params, input.extra_params, input.state, input.sequence);
    module->prepare(std::move(input));

    EXPECT_TRUE(can_objective_run_multiple_times(*module, &ITest<LSTMInput, LSTMOutput>::calculateJacobian));
}