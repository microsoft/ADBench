#pragma once

#include <cstdlib>
#include <cmath>

// Jacobian of LSTM (loss function)
void lstm_objective_d(
    int l,
    int c,
    int b,
    const double* const main_params,
    const double* const main_paramsd,
    const double* const extra_params,
    const double* const extra_paramsd,
    double* state,
    const double* const sequence,
    double* loss,
    double* lossd
);