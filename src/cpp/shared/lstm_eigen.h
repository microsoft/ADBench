#pragma once
#pragma warning (disable : 4996) // fopen

#include <vector>
#include <cmath>
#include <string>

#include "Eigen/Dense"

//using Eigen::Map;

// UTILS

template<typename T>
using ArrayX = Eigen::Array<T, 1, -1>;

//// Sigmoid on scalar
//template<typename T>
//T sigmoid(T x) {
//    return 1 / (1 + std::exp(-x));
//}
template<typename T>
const ArrayX<T>& sigmoid(const ArrayX<T>& x) {
    //return 1 / (1 + std::exp(-x));
    return inverse(exp(-x) + 1);
}

//// log(sum(exp(x), 2))
//template<typename T>
//T logsumexp(const T* vect, int sz) {
//    T sum = 0.0;
//    for (int i = 0; i < sz; ++i)
//        sum += std::exp(vect[i]);
//    sum += 2;
//    return log(sum);
//}
template<typename T>
const ArrayX<T>& logsumexp(const ArrayX<T>& vect) {
    ArrayX<T> sum;

    return log(exp(vect).sum() + 2);

    /*for (int i = 0; i < sz; ++i)
        sum += std::exp(vect[i]);
    sum += 2;
    return log(sum);*/
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
    //const T* forget;
    //const T* ingate;
    //const T* outgate;
    //const T* change;
    ArrayX<T> forget;
    ArrayX<T> ingate;
    ArrayX<T> outgate;
    ArrayX<T> change;

    WeightOrBias(const T* params, int hsize) :
        forget(params),
        ingate(&params[hsize]),
        outgate(&params[2 * hsize]),
        change(&params[3 * hsize])
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
    //const T* in_weight;
    //const T* out_weight;
    //const T* out_bias;
    ArrayX<T> in_weight;
    ArrayX<T> out_weight;
    ArrayX<T> out_bias;

    ExtraParams(const T* params, int hsize) :
        in_weight(params),
        out_weight(&params[hsize]),
        out_bias(&params[2 * hsize])
    {}
};

template<typename T>
struct InputSequence
{
    //std::vector<const T*> sequence;
    std::vector<ArrayX<T>> sequence;
    //T* -> ArrayX<T>
    //ArrayX<const T*> sequence;
    //ArrayX<T> sequence;

    InputSequence(const T* input_sequence, int char_bits, int char_count)
    {
        sequence.reserve(char_count);
        //sequence.resize(char_count);
        for (int i = 0; i < char_count; ++i)
        {
            //sequence.push_back(&input_sequence[char_bits * i]);
            sequence.push_back(Eigen::Map<ArrayX<T>>(&input_sequence[char_bits * i], 1, char_bits)); // ERROR some convertation problem here
            //Map<MatrixXd>(lightmatrix.data_, lightmatrix.nrows_, lightmatrix.ncols_)
            //sequence[i] = &input_sequence[char_bits * i]; // DANGER may rewrite some data existing in sequence.
        }
    }
};

template<typename T>
struct LayerState
{
    //T* hidden;
    //T* cell;
    ArrayX<T> hidden;
    ArrayX<T> cell;

    LayerState(T* layer_state, int hsize) :
        hidden(layer_state),
        cell(&layer_state[hsize])
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
//void lstm_model(int hsize,
//    const LayerParams<T>& params,
//    LayerState<T>& state,
//    const T* input)
{
    //for (int i = 0; i < hsize; ++i) {
    //    // gates for i-th cell/hidden
    //    T forget = sigmoid(input[i] * params.weight.forget[i] + params.bias.forget[i]);
    //    T ingate = sigmoid(state.hidden[i] * params.weight.ingate[i] + params.bias.ingate[i]);
    //    T outgate = sigmoid(input[i] * params.weight.outgate[i] + params.bias.outgate[i]);
    //    T change = tanh(state.hidden[i] * params.weight.change[i] + params.bias.change[i]);

    //    state.cell[i] = state.cell[i] * forget + ingate * change;
    //    state.hidden[i] = outgate * tanh(state.cell[i]);
    //}
    ArrayX<T> forget = sigmoid(input * params.weight.forget + params.bias.forget);
    ArrayX<T> ingate = sigmoid(state.hidden * params.weight.ingate + params.bias.ingate);
    ArrayX<T> outgate = sigmoid(input * params.weight.outgate + params.bias.outgate);
    ArrayX<T> change = tanh(state.hidden * params.weight.change + params.bias.change);

    state.cell = state.cell * forget + ingate * change;
    state.hidden = outgate * tanh(state.cell);
}
    
// Predict LSTM output given an input
template<typename T>
void lstm_predict(int l, int b,
    const MainParams<T>& main_params, const ExtraParams<T>& extra_params,
    State<T>& state,
    const ArrayX<T>& input, const ArrayX<T>& output)
//void lstm_predict(int l, int b,
//    const MainParams<T>& main_params, const ExtraParams<T>& extra_params,
//    State<T>& state,
//    const T* input, T* output)
{
    /*for (int i = 0; i < b; ++i)
        output[i] = input[i] * extra_params.in_weight[i];*/
    output = input * (ArrayX<T>)extra_params.in_weight; // DANGER types may be incompatible

    //T* layer_output = output;
    ArrayX<T> layer_output = output;

    for (int i = 0; i < l; ++i)
    {
        lstm_model(b, main_params.layer_params[i], state.layer_state[i], layer_output);
        layer_output = state.layer_state[i].hidden;
    }

    /*for (int i = 0; i < b; ++i)
        output[i] = layer_output[i] * extra_params.out_weight[i] + extra_params.out_bias[i];*/
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
        //ypred, new_state = predict(main_params, extra_params, all_states[t], _input)
        //all_states.append(new_state)
        //ynorm = ypred - torch.log(sum(torch.exp(ypred), 2))
        //ygold = sequence[t + 1]
        //total += sum(ygold * ynorm)
        //count += ygold.shape[0]
        //_input = ygold

        //lstm_predict(l, b, main_params_wrap, extra_params_wrap, state_wrap, sequence_wrap.sequence[t], ypred.data());
        lstm_predict(l, b, main_params_wrap, extra_params_wrap, state_wrap, sequence_wrap.sequence[t], ypred);

        /*T lse = logsumexp(ypred.data(), b);
        for (int i = 0; i < b; ++i)
            ynorm[i] = ypred[i] - lse;*/
        ynorm = ypred - logsumexp(ypred);//log(sum(exp(ypred), 2))

        //const T* ygold = sequence_wrap.sequence[t + 1];
        const ArrayX<T> ygold = sequence_wrap.sequence[t + 1];
        total += (ygold * ynorm).sum();
        /*for (int i = 0; i < b; ++i)
            total += ygold[i] * ynorm[i];*/

        count += b;
    }

    *loss = -total / count;
}
