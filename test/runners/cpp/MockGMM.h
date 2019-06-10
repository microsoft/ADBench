#pragma once

#include "../../../src/runners/cpp/ITest.h"
#include "../../../src/runners/cpp/GMMData.h"

class MockGMM : public ITest<GMMInput, GMMOutput> {
	// This function must be called before any other function.
	virtual void prepare(GMMInput&& input) override;

	virtual void calculateObjective(int times) override;
	virtual void calculateJacobian(int times) override;

	// 
	virtual GMMOutput output() override; //TODO: should be not void

	~MockGMM() {}

	// Inherited via ITest

};