// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once 

#include <vector>

#include "defs.h"
#include "utils.h"

struct BAInput {
    int n = 0, m = 0, p = 0;
    std::vector<double> cams, X, w, feats;
    std::vector<int> obs;
};

struct BAOutput {
    std::vector<double> reproj_err;
    std::vector<double> w_err;
    BASparseMat J;
};