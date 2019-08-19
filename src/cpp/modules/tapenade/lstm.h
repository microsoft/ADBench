#pragma once

#include <cstdlib>
#include <cmath>

// LSTM objective (loss function)
// Input variables: main_params, extra_params
// Output variable: loss
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