// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once 

#include <vector>

struct LSTMInput
{
    int l;
    int c;
    int b;
    std::vector<double> main_params;
    std::vector<double> extra_params;
    std::vector<double> state;
    std::vector<double> sequence;
};

struct LSTMOutput {
    double objective;
    std::vector<double> gradient;
};