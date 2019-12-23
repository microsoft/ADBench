// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once
#pragma warning (disable : 4996) // fopen

#include <vector>
#include <cmath>
#include <string>

#include "lstm_eigen_types.h"


// UTILS

// Sigmoid on vector
template<typename T>
ArrayX<T> sigmoid(const ArrayX<T>& x) {
    return (ArrayX<T>)inverse(exp(-x) + 1);
};

// log(sum(exp(x), 2))
template<typename T>
T logsumexp(const ArrayX<T>& vect) {

    return log(exp(vect).sum() + 2);
};


// Helper structures

template<typename T>
struct WeightOrBias
{
    MapConstX<T> forget;
    MapConstX<T> ingate;
    MapConstX<T> outgate;
    MapConstX<T> change;

    WeightOrBias(const T* params, int hsize) :
        forget(params, hsize),
        ingate(&params[hsize], hsize),
        outgate(&params[2 * hsize], hsize),
        change(&params[3 * hsize], hsize)
    {}
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
    MapConstX<T> in_weight;
    MapConstX<T> out_weight;
    MapConstX<T> out_bias;

    ExtraParams(const T* params, int hsize) :
        in_weight(params, hsize),
        out_weight(&params[hsize], hsize),
        out_bias(&params[2 * hsize], hsize)
    {}
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
    MapX<T> hidden;
    MapX<T> cell;

    LayerState(T* layer_state, int hsize) :
        hidden(layer_state, hsize),
        cell(&layer_state[hsize], hsize)
    {}
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
    ArrayX<T> forget(sigmoid((ArrayX<T>)(input * params.weight.forget + params.bias.forget)));
    ArrayX<T> ingate(sigmoid((ArrayX<T>)(state.hidden * params.weight.ingate + params.bias.ingate)));
    ArrayX<T> outgate(sigmoid((ArrayX<T>)(input * params.weight.outgate + params.bias.outgate)));
    ArrayX<T> change(tanh(state.hidden * params.weight.change + params.bias.change));

    state.cell = state.cell * forget + ingate * change;
    state.hidden = outgate * tanh(state.cell);
}

// Predict LSTM output given an input
template<typename T>
void lstm_predict(int l, int b,
    const MainParams<T>& main_params, const ExtraParams<T>& extra_params,
    State<T>& state,
    const ArrayX<T>& input, ArrayX<T>& output)
{
    output = input * extra_params.in_weight;
    ArrayX<T> layer_output = output;
    for (int i = 0; i < l; ++i)
    {
        lstm_model(b, main_params.layer_params[i], state.layer_state[i], layer_output);
        layer_output = state.layer_state[i].hidden;
    }
    output = layer_output * extra_params.out_weight + extra_params.out_bias;
}

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
        ynorm = ypred - logsumexp(ypred);
        const ArrayX<T> ygold = sequence_wrap.sequence[t + 1];

        total += (ygold * ynorm).sum();
        count += b;
    }

    *loss = -total / count;
}
