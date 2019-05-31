// ManualGMM.cpp : Defines the exported functions for the DLL.
#include "pch.h" // use pch.h in Visual Studio 2019
//#include <utility>
//#include <limits.h>
#include "ManualGMM.h"

// DLL internal state variables:
//static unsigned long long previous_;  // Previous value, if any
//static unsigned long long current_;   // Current sequence value
//static unsigned index_;               // Current seq. position


// This function must be called before any other function.
void ManualGMM::prepare(
	int d, int k, int n,
	vector<double> alphas, vector<double>means,
	vector<double> icf, vector<double> x,
	Wishart wishart,
	int nruns_f, int nruns_J,
	double time_limit)
{
	//save variables of ref in local state
}

void ManualGMM::performAD(int times)
{
	//perform AD and
	//save result in local state
}

// 
void ManualGMM::output()
{
	//return some documented output
}