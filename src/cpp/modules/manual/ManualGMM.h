// ManualGMM.h - Contains declarations of GMM tester functions
#pragma once

#include "../../shared/ITest.h"
#include "../../shared/GMMData.h"

#include <vector>

class ManualGMM : public ITest<GMMInput, GMMOutput> {
    GMMInput _input;
    GMMOutput _output;

public:
    // This function must be called before any other function.
    void prepare(GMMInput&& input) override;

    void calculateObjective(int times) override;
    void calculateJacobian(int times) override;
    GMMOutput output() override; 

    ~ManualGMM() = default;
};
