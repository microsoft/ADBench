#pragma once

#include <vector>

void lstm_objective_d(int l, int c, int b,
    const double* const main_params, const double* const extra_params,
    std::vector<double> state, const double* const sequence,
    double* loss, double* J);