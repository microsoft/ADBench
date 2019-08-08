// FiniteBA.h - Contains declarations of GMM tester functions
#pragma once

#include "../../shared/ITest.h"
#include "../../shared/BAData.h"
#include "finite.h"

#include <vector>

class FiniteBA : public ITest<BAInput, BAOutput> {
private:
    BAInput input;
    BAOutput result;
    std::vector<double> reproj_err_d;
    FiniteDifferencesEngine<double> engine;

public:
    // This function must be called before any other function.
    virtual void prepare(BAInput&& input) override;

    virtual void calculate_objective(int times) override;
    virtual void calculate_jacobian(int times) override;
    virtual BAOutput output() override;

    ~FiniteBA() = default;
};
