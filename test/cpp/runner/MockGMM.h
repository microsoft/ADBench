#pragma once

#include <gmock/gmock.h>

#include "../../../src/cpp/shared/ITest.h"
#include "../../../src/cpp/shared/GMMData.h"

class MockGMM : public ITest<GMMInput, GMMOutput> {
public:
    //This function must be called before any other function.
    void prepare(GMMInput&& input) override;

    MOCK_METHOD1(calculateObjective, void(int times));
    void calculateJacobian(int times) override;

    //Returns results of calculation
    GMMOutput output() override; 

    ~MockGMM() = default;

    // Inherited via ITest

};