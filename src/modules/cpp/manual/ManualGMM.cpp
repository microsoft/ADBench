// ManualGMM.cpp : Defines the exported functions for the DLL.
#include "ManualGMM.h"

#include <iostream>
#include <memory>

using namespace std;

// DLL internal state variables:
//static unsigned long long previous_;  // Previous value, if any
//static unsigned long long current_;   // Current sequence value
//static unsigned index_;               // Current seq. position

ManualGMM::ManualGMM() {}

// This function must be called before any other function.
void ManualGMM::prepare(GMMInput&& input)
{
	//save variables of ref in local state
	this->d = d;
	this->k = k;
	this->n = n;
	this->alphas = alphas;
	this->means = means;
	this->icf = icf;
	this->x = x;
	this->wishart = wishart;
	this->nruns_f = nruns_f;
	this->nruns_J = nruns_J;

	int icf_sz = d * (d + 1) / 2;
	int Jrows = 1;
	int Jcols = (k * (d + 1) * (d + 2)) / 2;
	this->J.resize(Jcols);
}

void ManualGMM::objective(int times)
{
	//gmm_objective(d, k, n, alphas.data(), means.data(),
	//	icf.data(), x.data(), wishart, &err);
}

void ManualGMM::objective_d(int times)
{
	//gmm_objective_d(d, k, n, alphas.data(), means.data(),
	//	icf.data(), x.data(), wishart, &err, J.data());
}

// 
GMMOutput ManualGMM::output()
{
	//return some documented output
	std::cout << "I am alive!" << endl;
	return GMMOutput();
}

void ManualGMM::calculateObjective(int times)
{
}

void ManualGMM::calculateJacobian(int times)
{
}

extern "C" __declspec(dllexport) ITest<GMMInput, GMMOutput>* __cdecl GetGMMTest()
{
	return new ManualGMM();
}
