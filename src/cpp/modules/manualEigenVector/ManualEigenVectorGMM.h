// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// ManualEigenVectorGMM.h - Contains declarations of GMM tester functions
#pragma once

#include "../../shared/ITest.h"
#include "../../shared/GMMData.h"

#include <vector>

class ManualEigenVectorGMM : public ITest<GMMInput, GMMOutput> {
    GMMInput _input;
    GMMOutput _output;

public:
    // This function must be called before any other function.
    void prepare(GMMInput&& input) override;

    void calculate_objective(int times) override;
    void calculate_jacobian(int times) override;
    GMMOutput output() override;

    ~ManualEigenVectorGMM() = default;
};
