// MockGMM.cpp : Defines the exported functions for the DLL.
#include "MockGMM.h"

#include <chrono>

extern "C" DLL_PUBLIC ITest<GMMInput, GMMOutput>* GetGMMTest()
{
    return new MockGMM();
}


