#pragma once

#include <cmath>
#include "../../shared/defs.h"



// Jacobian of reprojection error function, calculated in forward mode.
void compute_reproj_error_d(
    const double* const cam,
    const double* const camd,
    const double* const X,
    const double* const Xd,
    const double* const w,
    const double* const wd,
    const double* const feat,
    double* err,
    double* errd
);



// Jacobian of weight error function, calculated in forward mode.
void compute_zach_weight_error_d(
    const double* const w,
    const double* const wd,
    double* err,
    double* errd
);