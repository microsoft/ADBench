#pragma once

#include "../../shared/ITest.h"
#include "../../shared/GMMData.h"
#include "finite.h"

class FiniteGMM : public ITest<GMMInput, GMMOutput> {
    GMMInput _input;
    GMMOutput _output;
    FiniteDifferencesEngine<double> engine;

public:
    // This function must be called before any other function.
    void prepare(GMMInput&& input) override;

    void calculateObjective(int times) override;
    void calculateJacobian(int times) override;
    GMMOutput output() override;

    ~FiniteGMM() = default;
};