#pragma once

#include "../../../src/runners/cpp/IGMMTest.h"

class MockGMM : public IGMMTest {
	// This function must be called before any other function.
	void prepare(
		int d, int k, int n,
		vector<double>&& alphas, vector<double>&& means,
		vector<double>&& icf, vector<double>&& x,
		Wishart wishart,
		int nruns_f, int nruns_J);

	// perform AD
	void performAD(int times);

	// 
	void output(); //TODO: should be not void

	~MockGMM() {}
};