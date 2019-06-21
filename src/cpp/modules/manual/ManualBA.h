// ManualBA.h - Contains declarations of GMM tester functions
#pragma once

#include "../../shared/ITest.h"
#include "../../shared/BAData.h"

#include <vector>

class ManualBA : public ITest<BAInput, BAOutput> {
private:
    BAInput _input;
    BAOutput _output;

public:
    // This function must be called before any other function.
    virtual void prepare(BAInput&& input) override;

    virtual void calculateObjective(int times) override;
    virtual void calculateJacobian(int times) override;
    virtual BAOutput output() override;

    ~ManualBA() {}
};
