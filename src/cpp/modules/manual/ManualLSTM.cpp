// ManualLSTM.cpp : Defines the exported functions for the DLL.
#include "ManualLSTM.h"
#include "../../shared/lstm.h"

// This function must be called before any other function.
void ManualLSTM::prepare(LSTMInput&& input) : input(input)
{
    int Jcols = 0;
    output = { 0, std::vector<double>(Jcols) };
}

LSTMOutput ManualLSTM::output()
{
    return output;
}

// TODO: check whether the loop gets optimized away
void ManualLSTM::calculateObjective(int times)
{
    for (int i = 0; i < times; ++i) {
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
