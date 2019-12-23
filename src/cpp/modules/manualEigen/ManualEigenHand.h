// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// ManualEigenHand.h - Contains declarations of tester functions
#pragma once

#include "../../shared/ITest.h"
#include "../../shared/HandData.h"
#include "../../shared/HandEigenData.h"

#include <vector>

class ManualEigenHand : public ITest<HandInput, HandOutput> {
    HandEigenInput _input;
    HandOutput _output;
    bool _complicated;

public:
    // This function must be called before any other function.
    void prepare(HandInput&& input) override;

    void calculate_objective(int times) override;
    void calculate_jacobian(int times) override;
    HandOutput output() override;

    ~ManualEigenHand() = default;
};
