#pragma once 

#include <vector>

#include "utils.h"

struct HandInput
{
    std::vector<double> theta;
    HandDataLightMatrix data;
    std::vector<double> us;
};

struct HandOutput {
    std::vector<double> objective;
    std::vector<double> jacobian;
};