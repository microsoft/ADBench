// MockGMM.cpp : Defines the exported functions for the DLL.
#include "MockGMM.h"

#include <chrono>
#include <iostream>

extern "C" DLL_PUBLIC ITest<GMMInput, GMMOutput>* GetGMMTest()
{
    return new MockGMM();
}
