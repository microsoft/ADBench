// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once 

#include <vector>

#include "utils.h"

struct HandInput
{
    std::vector<double> theta;
    HandDataLightMatrix data;
    std::vector<double> us;
};

struct HandOutput {
    std::vector<double> objective;
    int jacobian_ncols, jacobian_nrows;
    std::vector<double> jacobian;
};

struct HandParameters {
    bool is_complicated;
};