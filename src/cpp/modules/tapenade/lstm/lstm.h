#pragma once

#include <cstdlib>
#include <cmath>

// LSTM objective (loss function)
// Input variables: main_params (8 * l * b), extra_params (3 * b)
// Output variable: loss (scalar)
// Parameters:
//      state (2 * l * b)
//      sequence (c * b)
void lstm_objective(
    int l,
    int c,
    int b,
    const double* const main_params,
    const double* const extra_params,
    double* state,
    const double* const sequence,
    double* loss
);