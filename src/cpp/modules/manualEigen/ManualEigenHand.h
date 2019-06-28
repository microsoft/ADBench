// ManualEigenHand.h - Contains declarations of tester functions
#pragma once

#include "../../shared/ITest.h"
#include "../../shared/HandData.h"
#include "HandEigenData.h"

#include <vector>

class ManualEigenHand : public ITest<HandInput, HandOutput> {
    HandEigenInput _input;
    HandOutput _output;
    bool _complicated;

public:
    // This function must be called before any other function.
    void prepare(HandInput&& input) override;

    void calculateObjective(int times) override;
    void calculateJacobian(int times) override;
    HandOutput output() override;

    ~ManualEigenHand() = default;
};
