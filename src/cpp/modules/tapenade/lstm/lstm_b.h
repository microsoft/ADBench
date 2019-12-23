// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

#include <stdlib.h>
#include <math.h>
    
#include "../utils/adBuffer.h"

// LSTM function differentiated in reverse mode by Tapenade.
void lstm_objective_b(
    int l,
    int c,
    int b,
    double const* main_params,
    double* main_paramsb,
    double const* extra_params,
    double* extra_paramsb,
    double* state,
    double const* sequence,
    double* loss,
    double* lossb
);

#ifdef __cplusplus
}
#endif