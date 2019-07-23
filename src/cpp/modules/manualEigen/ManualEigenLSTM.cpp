// ManualEigenLSTM.cpp : Defines the exported functions for the DLL.
#include "ManualEigenLSTM.h"
#include "../../shared/lstm.h"
#include "lstm_d.h"

// This function must be called before any other function.
void ManualEigenLSTM::prepare(LSTMInput&& input)
{
    this->input = input;
    int Jcols = 8 * input.l * input.b + 3 * input.b;
    state = std::vector<double>(input.state.size());
    result = { 0, std::vector<double>(Jcols) };
}

LSTMOutput ManualEigenLSTM::output()
{
    return result;
}

void ManualEigenLSTM::calculateObjective(int times)
{
    for (int i = 0; i < times; ++i) {
        state = input.state;
        lstm_objective(input.l, input.c, input.b, input.main_params.data(), input.extra_params.data(), state, input.sequence.data(), &result.objective);
    }
}

void ManualEigenLSTM::calculateJacobian(int times)
{
    for (int i = 0; i < times; ++i) {
        state = input.state;
        lstm_objective_d(input.l, input.c, input.b, input.main_params.data(), input.extra_params.data(), state, input.sequence.data(), &result.objective, result.gradient.data());
    }
}

extern "C" DLL_PUBLIC ITest<LSTMInput, LSTMOutput>*  GetLSTMTest()
{
    return new ManualEigenLSTM();
}
