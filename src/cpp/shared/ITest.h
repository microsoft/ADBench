#pragma once 

#include "defs.h"

template <typename Input, typename Output>
class ITest {
public:
    // This function must be called before any other function.
    virtual void prepare(Input&& input) = 0;
    // calculate function
    virtual void calculateObjective(int times) = 0;
    virtual void calculateJacobian(int times) = 0;
    virtual Output output() = 0;
    virtual ~ITest() = default;
};

// Factory function that creates instances of the GMMTester object.
// Should be declared in each module.
// extern "C" IGMMTesterAPI IGMMTester* APIENTRY GetGMMTester();