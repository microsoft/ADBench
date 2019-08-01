// FiniteBA.h - Contains declarations of GMM tester functions
#pragma once

#include "../../shared/ITest.h"
#include "../../shared/BAData.h"

#include <vector>

class FiniteBA : public ITest<BAInput, BAOutput> {
private:
    BAInput _input;
    BAOutput _output;
    std::vector<double> _reproj_err_d;

public:
    // This function must be called before any other function.
    virtual void prepare(BAInput&& input) override;

    virtual void calculateObjective(int times) override;
    virtual void calculateJacobian(int times) override;
    virtual BAOutput output() override;

    ~FiniteBA() = default;
};
