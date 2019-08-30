#include "lstm.h"

// UTILS
// Sigmoid on scalar
double sigmoid(double x)
{
    return 1.0 / (1.0 + exp(-x));
}

// log(sum(exp(x), 2))
double logsumexp(const double* const vect, int sz)
{
    double sum = 0.0;
    int i;

    for (i = 0; i < sz; i++)
    {
        sum += exp(vect[i]);
    }

    sum += 2;
    return log(sum);
}

// LSTM OBJECTIVE
// The LSTM model
void lstm_model(
    int hsize,
    const double* const weight,
    const double* const bias,
    double* hidden,
    double* cell,
    const double* const input
)
{
    double* gates = (double*)malloc(4 * hsize * sizeof(double));
    double* forget = &(gates[0]);
    double* ingate = &(gates[hsize]);
    double* outgate = &(gates[2 * hsize]);
    double* change = &(gates[3 * hsize]);

    int i;
    for (i = 0; i < hsize; i++)
    {
        forget[i] = sigmoid(input[i] * weight[i] + bias[i]);
        ingate[i] = sigmoid(hidden[i] * weight[hsize + i] + bias[hsize + i]);
        outgate[i] = sigmoid(input[i] * weight[2 * hsize + i] + bias[2 * hsize + i]);
        change[i] = tanh(hidden[i] * weight[3 * hsize + i] + bias[3 * hsize + i]);
    }

    for (i = 0; i < hsize; i++)
    {
        cell[i] = cell[i] * forget[i] + ingate[i] * change[i];
    }

    for (i = 0; i < hsize; i++)
    {
        hidden[i] = outgate[i] * tanh(cell[i]);
    }

    free(gates);
}

// Predict LSTM output given an input
void lstm_predict(
    int l,
    int b,
    const double* const w,
    const double* const w2,
    double* s,
    const double* const x,
    double* x2
)
{
    int i;
    for (i = 0; i < b; i++)
    {
        x2[i] = x[i] * w2[i];
    }

    double* xp = x2;
    for (i = 0; i <= 2 * l * b - 1; i += 2 * b)
    {
        lstm_model(b, &(w[i * 4]), &(w[(i + b) * 4]), &(s[i]), &(s[i + b]), xp);
        xp = &(s[i]);
    }

    for (i = 0; i < b; i++)
    {
        x2[i] = xp[i] * w2[b + i] + w2[2 * b + i];
    }
}

// LSTM objective (loss function)
void lstm_objective(
    int l,
    int c,
    int b,
    const double* const main_params,
    const double* const extra_params,
    double* state,
    const double* const sequence,
    double* loss
)
{
    int i, t;
    double total = 0.0;
    int count = 0;
    const double* input = &(sequence[0]);
    double* ypred = (double*)malloc(b * sizeof(double));
    double* ynorm = (double*)malloc(b * sizeof(double));
    const double* ygold;
    double lse;

    for (t = 0; t <= (c - 1) * b - 1; t += b)
    {
        lstm_predict(l, b, main_params, extra_params, state, input, ypred);
        lse = logsumexp(ypred, b);
        for (i = 0; i < b; i++)
        {
            ynorm[i] = ypred[i] - lse;
        }

        ygold = &(sequence[t + b]);
        for (i = 0; i < b; i++)
        {
            total += ygold[i] * ynorm[i];
        }

        count += b;
        input = ygold;
    }

    *loss = -total / count;

    free(ypred);
    free(ynorm);
}