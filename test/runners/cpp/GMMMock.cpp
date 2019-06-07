// GMMMock.cpp : Defines the exported functions for the DLL.
#include "GMMMock.h"

#include <iostream>
#include<memory>

// This function must be called before any other function.
void GMMMock::prepare(
	int d, int k, int n,
	vector<double>&& alphas, vector<double>&& means,
	vector<double>&& icf, vector<double>&& x,
	Wishart wishart,
	int nruns_f, int nruns_J)
{
	//save variables of ref in local state
}

void GMMMock::performAD(int times)
{
	//perform AD and
	//save result in local state
}

// 
void GMMMock::output()
{
	//return some documented output
	std::cout << "I am alive!" << endl;
}

extern "C" __declspec(dllexport) IGMMTest* __cdecl GetGMMTest()
{
	return new GMMMock();
}
