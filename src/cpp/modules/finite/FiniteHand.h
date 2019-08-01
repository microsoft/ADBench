// FiniteHand.h - Contains declarations of GMM tester functions
#pragma once

#include "../../shared/ITest.h"
#include "../../shared/HandData.h"

class FiniteHand : public ITest<HandInput, HandOutput> {
    HandInput _input;
    HandOutput _output;
    bool _complicated = false;
    std::vector<double> jacobian_by_us;
    std::vector<double> tmp_output;

public:
    // This function must be called before any other function.
    void prepare(HandInput&& input) override;

    void calculateObjective(int times) override;
    void calculateJacobian(int times) override;
    HandOutput output() override;

    ~FiniteHand() = default;
};