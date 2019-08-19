#include "TapenadeGMM.h"

// This function must be called before any other function.
void TapenadeGMM::prepare(GMMInput&& input)
{
	this->input = input;
	int Jcols = (this->input.k * (this->input.d + 1) * (this->input.d + 2)) / 2;

	alphas_d = std::vector<double>(input.alphas.size(), 0.0);
	means_d = std::vector<double>(input.means.size(), 0.0);
	icf_d = std::vector<double>(input.icf.size(), 0.0);

	result = { 0, std::vector<double>(Jcols) };
}



GMMOutput TapenadeGMM::output()
{
	return result;
}



void TapenadeGMM::calculate_objective(int times)
{
	for (int i = 0; i < times; i++)
	{
		gmm_objective(
			input.d,
			input.k,
			input.n,
			input.alphas.data(),
			input.means.data(),
			input.icf.data(),
			input.x.data(),
			input.wishart,
			&result.objective
		);
	}
}



void TapenadeGMM::calculate_jacobian(int times)
{
	int shift;
	for (int i = 0; i < times; i++)
	{
		// calculate alphas gradient part
		shift = 0;
		calculate_gradient_part(shift, alphas_d);

		// calculate means gradient part
		shift += input.alphas.size();
		calculate_gradient_part(shift, means_d);

		// calculate icf gradient part
		shift += input.means.size();
		calculate_gradient_part(shift, icf_d);
	}
}



void TapenadeGMM::calculate_gradient_part(int shift, std::vector<double>& directions)
{
	for (int i = 0; i < directions.size(); i++)
	{
		directions[i] = 1.0;	// set current direction
		if (i > 0)
		{
			directions[i - 1] = 0.0;	// erase last direction
		}

		gmm_objective_d(
			input.d,
			input.k,
			input.n,
			input.alphas.data(),
			alphas_d.data(),
			input.means.data(),
			means_d.data(),
			input.icf.data(),
			icf_d.data(),
			input.x.data(),
			input.wishart,
			&result.objective,
			&result.gradient[shift + i]
		);
	}

	directions.back() = 0.0;		// erase last direction
}



extern "C" DLL_PUBLIC ITest<GMMInput, GMMOutput>* get_gmm_test()
{
	return new TapenadeGMM();
}