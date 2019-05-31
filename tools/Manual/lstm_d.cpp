#pragma once
#pragma warning (disable : 4996) // fopen

#include <vector>

using std::vector;

// UTILS

// Sigmoid on scalar
template<typename T>
T sigmoid(T x) {
	return 1 / (1 + exp(-x));
}

// Sigmoid diff on scalar
template<typename T>
T sigmoid_d(T x) {
	return sigmoid(x) * (1 - sigmoid(x));
}

// tanh diff on scalar
template<typename T>
T tanh_d(T x) {
	return 1 - pow(tanh(x), 2);
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

// OBJECTIVE

// Manual derivative of lstm_model
//	seems to work
//	takes in pointers to where to output J
//	essentially outputs derivatives with
//	10 different pairs of variables
//	(the 2 outputs wrt 5 inputs each)
template<typename T>
void lstm_model_d(int hsize,
	const T* const weight, const T* const bias,
	T* hidden, T* cell,
	const T* const input,
	T* hidden_d_all, T* cell_d_all)
{
	// hidden and cell (outputs)
	// wrt weight, bias, hidden, cell, input
	T* hidden_dw = &hidden_d_all[0];
	T* hidden_db = &hidden_d_all[4 * hsize * hsize];
	T* hidden_dh = &hidden_d_all[8 * hsize * hsize];
	T* hidden_dc = &hidden_d_all[8 * hsize * hsize + hsize];
	T* hidden_di = &hidden_d_all[8 * hsize * hsize + 2 * hsize];
	T* cell_dw = &cell_d_all[0];
	T* cell_db = &cell_d_all[4 * hsize * hsize];
	T* cell_dh = &cell_d_all[8 * hsize * hsize];
	T* cell_dc = &cell_d_all[8 * hsize * hsize + hsize];
	T* cell_di = &cell_d_all[8 * hsize * hsize + 2 * hsize];
	// dw and db are full J matrices
	// but dh, dc, di are just vectors as cell[i]
	//	is only dependent on the ith term of
	//	each of these vectors

	for (int i = 0; i < hsize; i++) {
		// Only get relevant derivatives

		T forget_in = input[i] * weight[i] + bias[i];
		T forget = sigmoid(forget_in);
		T forget_sd = sigmoid_d(forget_in);
		T forget_dw = forget_sd * input[i];
		T forget_db = forget_sd;
		T forget_di = forget_sd * weight[i];

		T ingate_in = hidden[i] * weight[hsize + i] + bias[hsize + i];
		T ingate = sigmoid(ingate_in);
		T ingate_sd = sigmoid_d(ingate_in);
		T ingate_dw = ingate_sd * hidden[i];
		T ingate_db = ingate_sd;
		T ingate_dh = ingate_sd * weight[hsize + i];

		T outgate_in = input[i] * weight[2 * hsize + i] + bias[2 * hsize + i];
		T outgate = sigmoid(outgate_in);
		T outgate_sd = sigmoid_d(outgate_in);
		T outgate_dw = outgate_sd * input[i];
		T outgate_db = outgate_sd;
		T outgate_di = outgate_sd * weight[2 * hsize + i];

		T change_in = hidden[i] * weight[3 * hsize + i] + bias[3 * hsize + i];
		T change = tanh(change_in);
		T change_td = tanh_d(change_in);
		T change_dw = change_td * hidden[i];
		T change_db = change_td;
		T change_dh = change_td * weight[3 * hsize + i];

		// Cell derivatives

		T orig_cell = cell[i];
		cell[i] = orig_cell * forget + ingate * change;
		// wrt weight
		cell_dw[i * 4 * hsize + i] = orig_cell * forget_dw;
		cell_dw[i * 4 * hsize + hsize + i] = change * ingate_dw;
		cell_dw[i * 4 * hsize + 3 * hsize + i] = ingate * change_dw;
		// wrt bias
		cell_db[i * 4 * hsize + i] = orig_cell * forget_db;
		cell_db[i * 4 * hsize + hsize + i] = change * ingate_db;
		cell_db[i * 4 * hsize + 3 * hsize + i] = ingate * change_db;
		// wrt hidden, cell(original), input
		cell_dh[i] = ingate * change_dh + change * ingate_dh;
		cell_dc[i] = forget;
		cell_di[i] = orig_cell * forget_di;

		// Hidden derivatives

		T hidden_t = tanh(cell[i]);
		hidden[i] = outgate * hidden_t;
		T hidden_td = outgate * tanh_d(cell[i]);
		// wrt weight
		hidden_dw[i * 4 * hsize + i] = hidden_td * cell_dw[i * 4 * hsize + i];
		hidden_dw[i * 4 * hsize + hsize + i] = hidden_td * cell_dw[i * 4 * hsize + hsize + i];
		hidden_dw[i * 4 * hsize + 2 * hsize + i] = hidden_t * outgate_dw;
		hidden_dw[i * 4 * hsize + 3 * hsize + i] = hidden_td * cell_dw[i * 4 * hsize + 3 * hsize + i];
		// wrt bias
		hidden_db[i * 4 * hsize + i] = hidden_td * cell_db[i * 4 * hsize + i];
		hidden_db[i * 4 * hsize + hsize + i] = hidden_td * cell_db[i * 4 * hsize + hsize + i];
		hidden_db[i * 4 * hsize + 2 * hsize + i] = hidden_t * outgate_db;
		hidden_db[i * 4 * hsize + 3 * hsize + i] = hidden_td * cell_db[i * 4 * hsize + 3 * hsize + i];
		// wrt hidden, cell (original), input
		hidden_dh[i] = hidden_td * cell_dh[i];
		hidden_dc[i] = hidden_td * cell_dc[i];
		hidden_di[i] = outgate_di * hidden_t + hidden_td * cell_di[i];
	}
}


// Manual derivative of lstm_predict
//	NOTE this is not finished
//	but eventually it should give derivatives of:
//	x2 and s (outputs)
//	w.r.t. w, w2 and s (inputs)
template<typename T>
void lstm_predict_d(int l, int b,
	const T* const w, const T* const w2,
	T* s,
	const T* const x, T* x2)
{
	vector<T> x2_d_w2(3 * b);
	// x2 wrt w2
	// essentially 3 vectors, since each
	// x2[i] depends on w2[0, i], w2[1, i], w2[2, i]

	vector<T> x2_d_w(b * 2 * l * 4 * b);
	// shape = (b, l, 4 * b)
	// 3-D array to represent x2 (vector) wrt w (matrix)

	// Intial setup (from predict())
	for (int i = 0; i < b; i++) {
		x2[i] = x[i] * w2[i];
		x2_d_w2[3 * i] = x[i];
	}

	// Pointer to current x value
	T* xp = x2;

	// Derivative vectors for use in lstm_model_d
	//	named based on their relation to variables in lstm_predict_d
	vector<T> si_d_all(8 * b * b + 3 * b),
		si1_d_all(8 * b * b + 3 * b);
	// si_d_all is the result at &s[i] wrt all relevant variables
	// si1_d_all is the result at &s[i + b] wrt all relevant variables

	// Pointers to relevant points in these vectors
	//	(only 2 vectors passed for efficiency, but they
	//	represent lots of different data)
	T* si_d_wi = &si_d_all[0];
	T* si_d_wi1 = &si_d_all[4 * b * b];
	T* si_d_si = &si_d_all[8 * b * b];
	T* si_d_si1 = &si_d_all[8 * b * b + b];
	T* si_d_x = &si_d_all[8 * b * b + 2 * b];
	T* si1_d_wi = &si1_d_all[0];
	T* si1_d_wi1 = &si1_d_all[4 * b * b];
	T* si1_d_si = &si1_d_all[8 * b * b];
	T* si1_d_si1 = &si1_d_all[8 * b * b + b];
	T* si1_d_x = &si1_d_all[8 * b * b + 2 * b];

	// Main LSTM loop (from predict())
	for (int i = 0; i < 2 * l * b; i += 2 * b) {
		lstm_model_d(b, &w[i * 4], &w[(i + b) * 4], &s[i], &s[i + b], xp,
			si_d_all.data(), si1_d_all.data());
		xp = &s[i];

		// NOTE the following loop basically doesn't work
		//	but it may contain useful elements
		for (int j = 0; j < b; j++) {
			for (int k = 0; k < 4 * b; k++) {
				// TODO multiply the x2[prev]_d_w[:current]
				//	*= by x2[current]_d_x2[prev]
				// x2[prev]_d_w[:current] -> shape (b, i - 1, 4 * b)
				// x2[current]_d_x2[prev] -> shape (b, b)

				// Update the derivatives of x wrt all previous w[i] vals
				//	by multiplying by current_d_x
				//  where m is a layer
				for (int m = 0; m < i; m++) {
					x2_d_w[j * 2 * l * 4 * b + m * 4 + k] *= si_d_x[j];
					x2_d_w[j * 2 * l * 4 * b + (m + 1) * 4 + k] *= si_d_x[j];
				}

				// Set the derivative of x wrt current w[i] val
				x2_d_w[j * 2 * l * 4 * b + i * 4 + k] = si_d_wi[j * 4 * b + k];
				x2_d_w[j * 2 * l * 4 * b + (i + 1) * 4 + k] = si_d_wi1[j * 4 * b + k];
				// index is [j, i, k]
			}
		}

		std::cout << "loop" << std::endl;
	}

	// Final changes (from predict())
	for (int i = 0; i < b; i++) {
		x2[i] = xp[i] * w2[b + i] + w2[2 * b + i];

		// NOTE these should be correct
		x2_d_w2[3 * i + 1] = xp[i];
		x2_d_w2[3 * i + 2] = 1;
	}
	// x2 is the prediction
	// s (state) is also updated
}


// Derivative of main lstm_objective
//	loss (output)
//	w.r.t. main_params and extra_params (inputs)
//	NOTE this is not done
//	will need to be done after lstm_predict_d
template<typename T>
void lstm_objective_d(int l, int c, int b,
	const T* const main_params, const T* const extra_params,
	vector<T> state, const T* const sequence,
	T* loss, T* J)
{
	T total = 0.0;
	int count = 0;
	const T* input = &sequence[0];
	for (int t = 0; t < (c - 1) * b; t += b) {
		vector<T> ypred(b), ynorm(b);
		lstm_predict_d(l, b, main_params, extra_params, state.data(), input, ypred.data());

		T lse = logsumexp(ypred.data(), b);
		for (int i = 0; i < b; i++) ynorm[i] = ypred[i] - lse;

		const T* ygold = &sequence[t + b];
		for (int i = 0; i < b; i++) total += ygold[i] * ynorm[i];
		count += b;
		input = ygold;
	}

	std::cout << "total: " << total << std::endl;
	std::cout << "count: " << count << std::endl;

	*loss = -total / count;
}
