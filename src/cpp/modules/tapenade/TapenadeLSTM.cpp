#include "TapenadeLSTM.h"

void TapenadeLSTM::prepare(LSTMInput&& input)
{
	this->input = input;
	int Jcols = 8 * this->input.l * this->input.b + 3 * this->input.b;
	state = std::vector<double>(this->input.state.size());

	main_params_d = std::vector<double>(this->input.main_params.size(), 0.0);
	extra_params_d = std::vector<double>(this->input.extra_params.size(), 0.0);
	state_d = std::vector<double>(this->input.state.size(), 0.0);
	sequence_d = std::vector<double>(this->input.sequence.size(), 0.0);

	result = { 0, std::vector<double>(Jcols) };
}



LSTMOutput TapenadeLSTM::output()
{
	return result;
}



void TapenadeLSTM::calculate_objective(int times)
{
	for (int i = 0; i < times; i++)
	{
		state = input.state;
		lstm_objective(
			input.l,
			input.c,
			input.b,
			input.main_params.data(),
			input.extra_params.data(),
			state,
			input.sequence.data(),
			&result.objective
		);
	}
}



void TapenadeLSTM::calculate_jacobian(int times)
{
	int shift;
	for (int i = 0; i < times; i++)
	{
		// calculate main_params gradient part
		shift = 0;
		calculate_gradient_part(shift, main_params_d);

		// calculate extra_params gradient part
		shift += input.main_params.size();
		calculate_gradient_part(shift, extra_params_d);

		// calculate state gradient part
		shift += input.extra_params.size();
	    calculate_gradient_part(shift, state_d);

		// calculate sequence gradient part
		shift += input.state.size();
		calculate_gradient_part(shift, sequence_d);
	}
}



void TapenadeLSTM::calculate_gradient_part(int shift, std::vector<double>& directions)
{
	for (int i = 0; i < directions.size(); i++)
	{
		state = input.state;
		directions[i] = 1.0;	// set current direction
		if (i > 0)
		{
			directions[i - 1] = 0.0;	// erase last direction
		}

		lstm_objective_d(
			input.l,
			input.c,
			input.b,
			input.main_params.data(),
			main_params_d.data(),
			input.extra_params.data(),
			extra_params_d.data(),
			state.data(),
			state_d.data(),
			input.sequence.data(),
			sequence_d.data(),
			&result.objective,
			&result.gradient[shift + i]
		);
	}

	directions.back() = 0.0;		// erase last direction
}



extern "C" DLL_PUBLIC ITest<LSTMInput, LSTMOutput>* get_lstm_test()
{
	return new TapenadeLSTM();
}