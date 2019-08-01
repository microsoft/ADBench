// FiniteLSTM.h - Contains declarations of LSTM tester functions
#pragma once

#include "../../shared/ITest.h"
#include "../../shared/LSTMData.h"

#include <vector>

class FiniteLSTM : public ITest<LSTMInput, LSTMOutput> {
private:
    LSTMInput input;
    LSTMOutput result;
    std::vector<double> state;

public:
    // This function must be called before any other function.
    virtual void prepare(LSTMInput&& input) override;

    virtual void calculateObjective(int times) override;
    virtual void calculateJacobian(int times) override;
    virtual LSTMOutput output() override;

    ~FiniteLSTM() {}
};
