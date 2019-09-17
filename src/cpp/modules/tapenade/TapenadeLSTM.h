#pragma once

#include "../../shared/ITest.h"
#include "../../shared/LSTMData.h"

#include "lstm/lstm.h"
#include "lstm/lstm_b.h"

#include <vector>

class TapenadeLSTM : public ITest<LSTMInput, LSTMOutput>
{
private:
    LSTMInput input;
    LSTMOutput result;
    std::vector<double> state;

public:
    // This function must be called before any other function.
    virtual void prepare(LSTMInput&& input) override;

    virtual void calculate_objective(int times) override;
    virtual void calculate_jacobian(int times) override;
    virtual LSTMOutput output() override;

    ~TapenadeLSTM() {}
};

