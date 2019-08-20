#pragma once

#include <cstdlib>
#include <cmath>

#include "../../shared/defs.h"

// Jacobian of GMM
void gmm_objective_d(
    int d,
    int k,
    int n,
    const double* const alphas,
    const double* const alphasd,
    const double* const means,
    const double* const meansd,
    const double* const icf,
    const double* const icfd,
    const double* const x,
    Wishart wishart,
    double* err,
    double* errd
);