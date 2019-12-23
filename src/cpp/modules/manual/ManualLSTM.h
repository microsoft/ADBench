// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// ManualLSTM.h - Contains declarations of LSTM tester functions
#pragma once

#include "../../shared/ITest.h"
#include "../../shared/LSTMData.h"

#include <vector>

class ManualLSTM : public ITest<LSTMInput, LSTMOutput> {
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

    ~ManualLSTM() {}
};
