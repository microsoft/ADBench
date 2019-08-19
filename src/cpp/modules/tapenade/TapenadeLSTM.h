#pragma once

#include "../../shared/ITest.h"
#include "../../shared/LSTMData.h"

#include "lstm.h"
#include "lstm_d.h"

#include <vector>

class TapenadeLSTM : public ITest<LSTMInput, LSTMOutput>
{
private:
	LSTMInput input;
	LSTMOutput result;
	std::vector<double> state;

	// buffers for holding differentitation directions
	std::vector<double> main_params_d;
	std::vector<double> extra_params_d;

public:
	// This function must be called before any other function.
	virtual void prepare(LSTMInput&& input) override;

	virtual void calculate_objective(int times) override;
	virtual void calculate_jacobian(int times) override;
	virtual LSTMOutput output() override;

	~TapenadeLSTM() {}

private:
	// Calculates a part of a gradient.
	void calculate_gradient_part(int shift, std::vector<double>& directions);
};

