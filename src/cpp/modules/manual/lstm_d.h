#pragma once

#include <vector>

// Manual gradient of lstm_objective loss (output)
// with relation to main_params and extra_params (inputs)
void lstm_objective_d(int l, int c, int b,
    const double* const main_params, const double* const extra_params,
    std::vector<double> state, const double* const sequence,
    double* loss, double* J);