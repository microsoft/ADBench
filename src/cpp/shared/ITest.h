// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once 

#if defined _WIN32 || defined __CYGWIN__
    #ifdef __GNUC__
        #define DLL_PUBLIC __attribute__ ((dllexport))
    #else
        #define DLL_PUBLIC __declspec(dllexport) // Note: actually gcc seems to also supports this syntax.
    #endif
#else
  #if __GNUC__ >= 4
    #define DLL_PUBLIC __attribute__ ((visibility ("default")))
  #else
    #define DLL_PUBLIC
  #endif
#endif

#include <ostream>

template <typename Input, typename Output>
class ITest {
public:
    // This function must be called before any other function.
    virtual void prepare(Input&& input) = 0;
    // calculate function
    virtual void calculate_objective(int times) = 0;
    virtual void calculate_jacobian(int times) = 0;
    virtual Output output() = 0;
    virtual ~ITest() = 0;
};

template <typename Input, typename Output>
ITest<Input, Output>::~ITest() = default;

// Factory function that creates instances of the GMMTester object.
// Should be declared in each module.
// extern "C" DLL_PUBLIC ITest<Input,Output>* GetGMMTester();