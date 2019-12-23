// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// FiniteHand.h - Contains declarations of GMM tester functions
#pragma once

#include "../../shared/ITest.h"
#include "../../shared/HandData.h"
#include "finite.h"

class FiniteHand : public ITest<HandInput, HandOutput> {
    HandInput input;
    HandOutput result;
    bool complicated = false;
    std::vector<double> jacobian_by_us;
    FiniteDifferencesEngine<double> engine;

public:
    // This function must be called before any other function.
    void prepare(HandInput&& input) override;

    void calculate_objective(int times) override;
    void calculate_jacobian(int times) override;
    HandOutput output() override;

    ~FiniteHand() = default;
};