#pragma once 

#include "../../shared/hand_eigen_model.h"

#include <Eigen/Dense>
#include <Eigen/StdVector>

struct HandEigenInput
{
    std::vector<double> theta;
    HandDataEigen data;
    std::vector<double> us;
};