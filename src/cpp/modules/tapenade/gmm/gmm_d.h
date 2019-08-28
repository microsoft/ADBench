#pragma once

#include <cstdlib>
#include <cmath>

#include "../utils/adBuffer.h"
#include "../../../shared/defs.h"

// GMM function deffirintiated in reverse mode by Tapenade.
void gmm_objective_b(
    int d,
    int k,
    int n,
    const double* const alphas,
    double* alphasb,
    const double* const means,
    double* meansb,
    const double* const icf,
    double* icfb,
    const double* const x,
    Wishart wishart,
    double* err,
    double* errb
);