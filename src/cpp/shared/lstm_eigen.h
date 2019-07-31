#pragma once
#pragma warning (disable : 4996) // fopen

#include <vector>
#include <cmath>
#include <string>

#include "Eigen/Dense"

using Eigen::Map;
template<typename T>
using ArrayX = Eigen::Array<T, -1, 1>;

// UTILS

// Sigmoid on scalar
template<typename T>
T sigmoid(T x) {
    return 1 / (1 + std::exp(-x));
}

// log(sum(exp(x), 2))
template<typename T>
T logsumexp(const T* vect, int sz) {
    T sum = 0.0;
    for (int i = 0; i < sz; ++i)
        sum += std::exp(vect[i]);
    sum += 2;
    return log(sum);
}

// log(sum(exp(x), 2))
template<typename T>
T logsumexp_store_temps(const T* vect, int sz) {
    std::vector<T> vect2(sz);
    for (int i = 0; i < sz; ++i)
        vect2[i] = exp(vect[i]);
    T sum = 0.0;
    for (int i = 0; i < sz; ++i)
        sum += vect2[i];
    sum += 2;
    return log(sum);
}

// Helper structures

template<typename T>
struct WeightOrBias
{
    //const T*
    ArrayX<T> forget;
    ArrayX<T> ingate;
    ArrayX<T> outgate;
    ArrayX<T> change;

    WeightOrBias(const T* params, int hsize)
    {
        forget = Map<const ArrayX<T>>(params, hsize);
        ingate = Map<const ArrayX<T>>(&params[hsize], hsize);
        outgate = Map<const ArrayX<T>>(&params[2 * hsize], hsize);
        change = Map<const ArrayX<T>>(&params[3 * hsize], hsize);
    }
};

template<typename T>
struct LayerParams
{
    const WeightOrBias<T> weight;
    const WeightOrBias<T> bias;

    LayerParams(const T* layer_params, int hsize) :
        weight(layer_params, hsize),
        bias(&layer_params[hsize * 4], hsize)
    {}
};

template<typename T>
struct MainParams
{
    std::vector<LayerParams<T>> layer_params;

    MainParams(const T* main_params, int hsize, int n_layers)
    {
        layer_params.reserve(n_layers);
        for (int i = 0; i < n_layers; ++i)
        {
            layer_params.emplace_back(&main_params[8 * hsize * i], hsize);
        }
    }
};

template<typename T>
struct ExtraParams
{
    //const T*
    ArrayX<T> in_weight;
    ArrayX<T> out_weight;
    ArrayX<T> out_bias;

    ExtraParams(const T* params, int hsize)
    {
        in_weight = Map<const ArrayX<T>>(params, hsize);
        out_weight = Map<const ArrayX<T>>(&params[hsize], hsize);
        out_bias = Map<const ArrayX<T>>(&params[2 * hsize], hsize);
    }
};

template<typename T>
struct InputSequence
{
    std::vector<ArrayX<T>> sequence;

    InputSequence(const T* input_sequence, int char_bits, int char_count)
    {
        sequence.reserve(char_count);
        for (int i = 0; i < char_count; ++i)
        {
            sequence.push_back(Map<const ArrayX<T>>(&input_sequence[char_bits * i], char_bits));
        }
    }
};

template<typename T>
struct LayerState
{
    //T*
    ArrayX<T> hidden;
    ArrayX<T> cell;

    LayerState(T* layer_state, int hsize)
    {
        hidden = Map<ArrayX<T>>(layer_state, hsize);
        cell = Map<ArrayX<T>>(&layer_state[hsize], hsize);
    }
};

template<typename T>
struct State
{
    std::vector<LayerState<T>> layer_state;

    State(T* state, int hsize, int n_layers)
    {
        layer_state.reserve(n_layers);
        for (int i = 0; i < n_layers; ++i)
        {
            layer_state.emplace_back(&state[2 * hsize * i], hsize);
        }
    }
};

// LSTM OBJECTIVE

// The LSTM model
template<typename T>
void lstm_model(int hsize,
    const LayerParams<T>& params,
    LayerState<T>& state,
    const ArrayX<T>& input)
{
    for (int i = 0; i < hsize; ++i) {
        // gates for i-th cell/hidden
        T forget = sigmoid(input[i] * params.weight.forget[i] + params.bias.forget[i]);
        T ingate = sigmoid(state.hidden[i] * params.weight.ingate[i] + params.bias.ingate[i]);
        T outgate = sigmoid(input[i] * params.weight.outgate[i] + params.bias.outgate[i]);
        T change = tanh(state.hidden[i] * params.weight.change[i] + params.bias.change[i]);

        state.cell[i] = state.cell[i] * forget + ingate * change;
        state.hidden[i] = outgate * tanh(state.cell[i]);
    }
}
//# The LSTM model
//def lstm(weight, bias, hidden, cell, _input) :
//    # NOTE this line came from : gates = hcat(input, hidden) * weight . + bias
//    gates = torch.cat((_input, hidden, _input, hidden)) * weight + bias
//    hsize = hidden.shape[0]
//    forget = torch.sigmoid(gates[0:hsize])
//    ingate = torch.sigmoid(gates[hsize:2 * hsize])
//    outgate = torch.sigmoid(gates[2 * hsize:3 * hsize])
//    change = torch.tanh(gates[3 * hsize:])
//    cell = cell * forget + ingate * change
//    hidden = outgate * torch.tanh(cell)
//    return (hidden, cell)
    
// Predict LSTM output given an input
template<typename T>
void lstm_predict(int l, int b,
    const MainParams<T>& main_params, const ExtraParams<T>& extra_params,
    State<T>& state,
    const ArrayX<T>& input, ArrayX<T>& output)
{
    for (int i = 0; i < b; ++i)
        output[i] = input[i] * extra_params.in_weight[i];

    ArrayX<T> layer_output = output;

    for (int i = 0; i < l; ++i)
    {
        lstm_model(b, main_params.layer_params[i], state.layer_state[i], layer_output);
        layer_output = state.layer_state[i].hidden;
    }

    for (int i = 0; i < b; ++i)
        output(i) = layer_output[i] * extra_params.out_weight[i] + extra_params.out_bias[i];
}
//# Predict output given an input
//def predict(w, w2, s, x) :
//    s2 = torch.tensor(s)
//    # NOTE not sure if this should be element - wise or matrix multiplication
//    x = x * w2[0]
//    for i in range(0, len(s), 2) :
//        (s2[i], s2[i + 1]) = lstm(w[i], w[i + 1], s[i], s[i + 1], x)
//        x = s2[i]
//        return (x * w2[1] + w2[2], s2)
    

// LSTM objective (loss function)
template<typename T>
void lstm_objective(int l, int c, int b, 
    const T* main_params, const T* extra_params,
    std::vector<T> state, const T* sequence,
    T* loss)
{
    T total = 0.0;
    int count = 0;
    MainParams<T> main_params_wrap(main_params, b, l);
    ExtraParams<T> extra_params_wrap(extra_params, b);
    State<T> state_wrap(state.data(), b, l);
    InputSequence<T> sequence_wrap(sequence, b, c);
    ArrayX<T> ypred(b), ynorm(b);
    for (int t = 0; t < c - 1; ++t)
    {
        lstm_predict(l, b, main_params_wrap, extra_params_wrap, state_wrap, sequence_wrap.sequence[t], ypred);

        T lse = logsumexp(ypred.data(), b);
        for (int i = 0; i < b; ++i)
            ynorm[i] = ypred[i] - lse;

        const ArrayX<T> ygold = sequence_wrap.sequence[t + 1];
        for (int i = 0; i < b; ++i)
            total += ygold[i] * ynorm[i];

        count += b;
    }

    *loss = -total / count;
}
//# Get the average loss for the LSTM across a sequence of inputs
//def loss(main_params, extra_params, state, sequence, _range = None) :
//    if _range is None :
//_range = range(0, len(sequence) - 1)
//
//total = 0.0
//count = 0
//_input = sequence[_range[0]]
//all_states = [state]
//for t in _range :
//ypred, new_state = predict(main_params, extra_params, all_states[t], _input)
//all_states.append(new_state)
//ynorm = ypred - torch.log(sum(torch.exp(ypred), 2))
//ygold = sequence[t + 1]
//total += sum(ygold * ynorm)
//count += ygold.shape[0]
//_input = ygold
//return -total / count
