// GMMDummy.cpp : Defines the exported functions for the DLL.
#include "GMMMock.h"

#include <iostream>
#include<memory>

// This function must be called before any other function.
void GMMDummy::prepare(
	int d, int k, int n,
	vector<double>&& alphas, vector<double>&& means,
	vector<double>&& icf, vector<double>&& x,
	Wishart wishart,
	int nruns_f, int nruns_J)
{
	//save variables of ref in local state
}

void GMMDummy::performAD(int times)
{
	std::chrono::seconds(2)

}

// 
void GMMDummy::output()
{
	//return some documented output
	std::cout << "I am alive!" << endl;
}

extern "C" __declspec(dllexport) IGMMTest* __cdecl GetGMMTest()
{
	return new GMMDummy();
}
