// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once 

#include <vector>

#include "defs.h"

struct GMMInput {
    int d, k, n;
    std::vector<double> alphas, means, icf, x;
    Wishart wishart;
};

struct GMMOutput {
    double objective;
    std::vector<double> gradient;
};

struct GMMParameters {
    bool replicate_point;
};