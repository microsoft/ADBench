// ManualBA.cpp : Defines the exported functions for the DLL.
#include "ManualBA.h"
#include "../../shared/ba.h"
#include "ba_d.h"

#include <iostream>
#include <memory>

// This function must be called before any other function.
void ManualBA::prepare(BAInput&& input)
{
	_input = input;
	_output = { std::vector<double>(2 * _input.p), std::vector<double>(_input.p), BASparseMat(_input.n, _input.m, _input.p) };
}

BAOutput ManualBA::output()
{
	return _output;
}

// TODO: check whether the loop gets optimized away
void ManualBA::calculateObjective(int times)
{
	for (int i = 0; i < times; ++i) {
		ba_objective(_input.n, _input.m, _input.p, _input.cams.data(), _input.X.data(), _input.w.data(),
			_input.obs.data(), _input.feats.data(), _output.reproj_err.data(), _output.w_err.data());
	}
}

void ManualBA::calculateJacobian(int times)
{
	int n_new_cols = BA_NCAMPARAMS + 3 + 1;
	std::vector<double> reproj_err_d(2 * n_new_cols);
	for (int i = 0; i < times; ++i) {
		_output.J.clear();
		for (int i = 0; i < _input.p; i++)
		{
			std::fill(reproj_err_d.begin(), reproj_err_d.end(), (double)0);
			//memset(reproj_err_d.data(), 0, 2 * n_new_cols*sizeof(double));

			int camIdx = _input.obs[2 * i + 0];
			int ptIdx = _input.obs[2 * i + 1];
			computeReprojError_d(
				&_input.cams[BA_NCAMPARAMS * camIdx],
				&_input.X[ptIdx * 3],
				_input.w[i],
				_input.feats[2 * i + 0], _input.feats[2 * i + 1],
				&_output.reproj_err[2 * i],
				reproj_err_d.data());

			_output.J.insert_reproj_err_block(i, camIdx, ptIdx, reproj_err_d.data());
		}

		for (int i = 0; i < _input.p; i++)
		{
			double w_d = 0;
			computeZachWeightError_d(_input.w[i], &_output.w_err[i], &w_d);

			_output.J.insert_w_err_block(i, w_d);
		}
	}
}

extern "C" __declspec(dllexport) ITest<BAInput, BAOutput>* __cdecl GetBATest()
{
	return new ManualBA();
}
