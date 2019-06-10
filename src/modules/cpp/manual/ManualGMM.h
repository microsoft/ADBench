// ManualGMM.h - Contains declarations of GMM tester functions
#pragma once

#include "../../../runners/cpp/ITest.h"
#include "../../../runners/cpp/GMMData.h"

class ManualGMM : public ITest<GMMInput, GMMOutput> {
private:
	int d = 0, k = 0, n = 0;
	vector<double> alphas, means, icf, x, J;
	Wishart wishart = { 0, 0 };
	double err = 0;

public:
	// This function must be called before any other function.
	virtual void prepare(GMMInput&& input) override;

	// Inherited via ITest
	virtual void calculateObjective(int times) override;
	virtual void calculateJacobian(int times) override;

	// 
	virtual GMMOutput output() override; //TODO: should be not void

	~ManualGMM() {}
};
