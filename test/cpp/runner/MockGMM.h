#pragma once

#include <gmock/gmock.h>

#include "../../../src/cpp/shared/ITest.h"
#include "../../../src/cpp/shared/GMMData.h"

class MockGMM : public ITest<GMMInput, GMMOutput> {
public:
    //This function must be called before any other function.    
    void prepare(GMMInput&& input) { prepare(input); }
    MOCK_METHOD1(prepare, void(const GMMInput& input));

    MOCK_METHOD1(calculateObjective, void(int times));
    MOCK_METHOD1(calculateJacobian, void(int times));

    //Returns results of calculation
    MOCK_METHOD0(output, GMMOutput());

    ~MockGMM() = default;
};