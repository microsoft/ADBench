// ManualGMM.h - Contains declarations of GMM tester functions
#pragma once

#include "../../shared/ITest.h"
#include "../../shared/GMMData.h"

#include <vector>

class ManualGMM : public ITest<GMMInput, GMMOutput> {
private:
    GMMInput _input;
    GMMOutput _output;

public:
    // This function must be called before any other function.
    virtual void prepare(GMMInput&& input) override;

    virtual void calculateObjective(int times) override;
    virtual void calculateJacobian(int times) override;
    virtual GMMOutput output() override;

    ~ManualGMM() {}
};
