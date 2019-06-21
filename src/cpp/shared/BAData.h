#pragma once 

#include <vector>

#include "defs.h"
#include "utils.h"

struct BAInput {
    int n, m, p;
    std::vector<double> cams, X, w, feats;
    std::vector<int> obs;
};

struct BAOutput {
    std::vector<double> reproj_err;
    std::vector<double> w_err;
    BASparseMat J;
};