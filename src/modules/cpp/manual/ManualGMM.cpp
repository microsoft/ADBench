// ManualGMM.cpp : Defines the exported functions for the DLL.
#include "ManualGMM.h"

#include <iostream>
#include<memory>

using namespace std;

// DLL internal state variables:
//static unsigned long long previous_;  // Previous value, if any
//static unsigned long long current_;   // Current sequence value
//static unsigned index_;               // Current seq. position


// This function must be called before any other function.
void ManualGMM::prepare(GMMInput&& input)
{
	//save variables of ref in local state
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
