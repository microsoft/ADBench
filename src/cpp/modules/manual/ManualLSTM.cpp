// ManualLSTM.cpp : Defines the exported functions for the DLL.
#include "ManualLSTM.h"
#include "../../shared/lstm.h"

// This function must be called before any other function.
void ManualLSTM::prepare(LSTMInput&& input)
{
    this->input = input;
    int Jcols = 0;
    state = std::vector<double>(input.state.size());
    result = { 0, std::vector<double>(Jcols) };
}

LSTMOutput ManualLSTM::output()
{
    return result;
}

// TODO: check whether the loop gets optimized away
void ManualLSTM::calculateObjective(int times)
{
    for (int i = 0; i < times; ++i) {
        state = input.state;
        lstm_objective(input.l, input.c, input.b, input.main_params.data(), input.extra_params.data(), state, input.sequence.data(), &result.objective);
    }
}

void ManualLSTM::calculateJacobian(int times)
{
    for (int i = 0; i < times; ++i) {
    }
}

extern "C" __declspec(dllexport) ITest<LSTMInput, LSTMOutput>* __cdecl GetLSTMTest()
{
    return new ManualLSTM();
}
