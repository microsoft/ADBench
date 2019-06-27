#pragma once 

#include "utils.h"

#include <Eigen/Dense>
#include <Eigen/StdVector>

struct HandEigenInput
{
    std::vector<double> theta;
    HandDataEigen data;
    std::vector<double> us;
};