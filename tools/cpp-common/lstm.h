#pragma once
#pragma warning (disable : 4996) // fopen

#include <vector>

using std::vector;
using std::string;

// UTILS

// Sigmoid on scalar
template<typename T>
T sigmoid(T x) {
	return 1 / (1 + exp(-x));
}

// log(sum(exp(x), 2))
template<typename T>
T logsumexp(const T* const vect, int sz) {
	vector<T> vect2(sz);
	for (int i = 0; i < sz; i++) vect2[i] = exp(vect[i]);
	T sum = 0.0;
	for (int i = 0; i < sz; i++) sum += vect2[i];
	sum += 2;
	return log(sum);
}

// LSTM OBJECTIVE

// The LSTM model
template<typename T>
void lstm_model(int hsize,
	const T* const weight, const T* const bias,
	T* hidden, T* cell,
	const T* const input)
{
	vector<T> gates(4 * hsize);
	T* forget = &gates[0];
	T* ingate = &gates[hsize];
	T* outgate = &gates[2 * hsize];
	T* change = &gates[3 * hsize];
	for (int i = 0; i < hsize; i++) {
		forget[i] = sigmoid(input[i] * weight[i] + bias[i]);
		ingate[i] = sigmoid(hidden[i] * weight[hsize + i] + bias[hsize + i]);
		outgate[i] = sigmoid(input[i] * weight[2 * hsize + i] + bias[2 * hsize + i]);
		change[i] = tanh(hidden[i] * weight[3 * hsize + i] + bias[3 * hsize + i]);
	}

	for (int i = 0; i < hsize; i++) cell[i] = cell[i] * forget[i] + ingate[i] * change[i];
	for (int i = 0; i < hsize; i++) hidden[i] = outgate[i] * tanh(cell[i]);
}
	
// Predict LSTM output given an input
template<typename T>
void lstm_predict(int l, int b,
	const T* const w, const T* const w2,
	T* s,
	const T* const x, T* x2)
{
	for (int i = 0; i < b; i++) x2[i] = x[i] * w2[0];

	T* xp = x2;

	for (int i = 0; i < 2 * l * b; i += 2 * b) {
		lstm_model(b, &w[i * 4], &w[(i + b) * 4], &s[i], &s[i + b], xp);
		xp = &s[i];
	}

	for (int i = 0; i < b; i++) x2[i] = xp[i] * w2[b + i] + w2[2 * b + i];
}
	

// LSTM objective (loss function)
template<typename T>
void lstm_objective(int l, int c, int b, 
	const T* const main_params, const T* const extra_params,
	vector<T> state, const T* const sequence,
	T* loss)
{
	T total = 0.0;
	int count = 0;
	const T* input = &sequence[0];
	for (int t = 0; t < (c - 1) * b; t += b) {
		vector<T> ypred(b), ynorm(b);
		lstm_predict(l, b, main_params, extra_params, state.data(), input, ypred.data());

		T lse = logsumexp(ypred.data(), b);
		for (int i = 0; i < b; i++) ynorm[i] = ypred[i] - lse;

		const T* ygold = &sequence[t + b];
		for (int i = 0; i < b; i++) total += ygold[i] * ynorm[i];

		count += b;
		input = ygold;
	}

	*loss = -total / count;
}
