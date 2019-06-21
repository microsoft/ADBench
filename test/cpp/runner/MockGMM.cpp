// MockGMM.cpp : Defines the exported functions for the DLL.
#include "MockGMM.h"

#include <chrono>
#include <iostream>
#include <memory>

// This function must be called before any other function.
void MockGMM::prepare(GMMInput&& input)
{
    //save variables of ref in local state
}

// 
GMMOutput MockGMM::output()
{
    //return some documented output
    std::cout << "I am alive!" << std::endl;
    return GMMOutput();
}

void MockGMM::calculateObjective(int times)
{
}

void MockGMM::calculateJacobian(int times)
{
}

extern "C" __declspec(dllexport) ITest<GMMInput, GMMOutput>* __cdecl GetGMMTest()
{
    return new MockGMM();
}
