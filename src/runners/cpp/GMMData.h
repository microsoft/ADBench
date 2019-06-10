#pragma once 

#include <vector>

#include "../../modules/cpp/shared/defs.h"

struct GMMInput {
	int d, k, n;
	std::vector<double> alphas, means, icf, x;
	Wishart wishart;
};

struct GMMOutput {

};