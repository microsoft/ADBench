// ManualHand.h - Contains declarations of GMM tester functions
#pragma once

#include "../../shared/ITest.h"
#include "../../shared/HandData.h"

class ManualHand : public ITest<HandInput, HandOutput> {
    HandInput _input;
    HandOutput _output;
    bool _complicated = false;

public:
    // This function must be called before any other function.
    void prepare(HandInput&& input) override;

    void calculate_objective(int times) override;
    void calculate_jacobian(int times) override;
    HandOutput output() override;

    ~ManualHand() = default;
};