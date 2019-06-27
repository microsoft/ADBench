// ManualHand.h - Contains declarations of GMM tester functions
#pragma once

#include "../../shared/ITest.h"
#include "../../shared/HandData.h"

class ManualHand : public ITest<HandInput, HandOutput> {
    HandInput _input;
    HandOutput _output;
    bool _complicated;

public:
    // This function must be called before any other function.
    void prepare(HandInput&& input) override;

    void calculateObjective(int times) override;
    void calculateJacobian(int times) override;
    HandOutput output() override;

    ~ManualHand() = default;
};