#pragma once

#include "../../shared/ITest.h"
#include "../../shared/GMMData.h"

#include "gmm.h"
#include "gmm_d.h"

#include <vector>

class TapenadeGMM : public ITest<GMMInput, GMMOutput>
{
private:
	GMMInput input;
	GMMOutput result;
	std::vector<double> state;

	// buffers for holding differentitation directions
	std::vector<double> alphas_d;
	std::vector<double> means_d;
	std::vector<double> icf_d;

public:
	// This function must be called before any other function.
	virtual void prepare(GMMInput&& input) override;

	virtual void calculate_objective(int times) override;
	virtual void calculate_jacobian(int times) override;
	virtual GMMOutput output() override;

	~TapenadeGMM() {}

private:
	// Calculates a part of a gradient.
	void calculate_gradient_part(int shift, std::vector<double>& directions);
};

