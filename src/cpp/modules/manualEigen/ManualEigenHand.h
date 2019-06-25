// ManualEigenHand.h - Contains declarations of GMM tester functions
#pragma once

#include "../../shared/ITest.h"
#include "../../shared/HandData.h"

#include <vector>

class ManualEigenHand : public ITest<HandInput, HandOutput> {
    HandInput _input;
    HandOutput _output;

public:
    // This function must be called before any other function.
    void prepare(HandInput&& input) override;

    void calculateObjective(int times) override;
    void calculateJacobian(int times) override;
    HandOutput output() override;

    ~ManualEigenHand() = default;
};
