#pragma once 

#if __GNUC__ >= 4
#define DLL_PUBLIC __attribute__ ((visibility("default")))
#else
#define DLL_PUBLIC __declspec(dllexport)
#endif
#include <ostream>

template <typename Input, typename Output>
class ITest {
public:
    // This function must be called before any other function.
    virtual void prepare(Input&& input) = 0;
    // calculate function
    virtual void calculateObjective(int times) = 0;
    virtual void calculateJacobian(int times) = 0;
    virtual Output output() = 0;
    virtual ~ITest() = 0;
};

template <typename Input, typename Output>
ITest<Input, Output>::~ITest() = default;

// Factory function that creates instances of the GMMTester object.
// Should be declared in each module.
// extern "C" DLL_PUBLIC ITest<Input,Output>* GetGMMTester();