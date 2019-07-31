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

// Sigmoid on arrays
template<typename T>
ArrayX<T> sigmoid(ArrayX<T>& x) {
    return (ArrayX<T>)inverse(exp(-x) + 1);
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
    for (int i = 0; i < b; ++i)
        output[i] = input[i] * extra_params.in_weight[i];

    ArrayX<T> layer_output = output;

    for (int i = 0; i < l; ++i)
    {
        lstm_model(b, main_params.layer_params[i], state.layer_state[i], layer_output);
        layer_output = state.layer_state[i].hidden;
    }

    for (int i = 0; i < b; ++i)
        output[i] = layer_output[i] * extra_params.out_weight[i] + extra_params.out_bias[i];
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


/*
//*******|||||||||||||||||||||||||||||||||*************
//*****************************************************
//*******|||||||||||||||||||||||||||||||||*************


#pragma once
#pragma warning (disable : 4996) // fopen

#include <vector>
#include <cmath>
#include <string>

#include <Eigen/Dense>
#include <Eigen/StdVector>

using Eigen::Map;

// UTILS

template<typename T>
using ArrayX = Eigen::Array<T, -1, 1>;

//// Sigmoid on scalar
//template<typename T>
//T sigmoid(T x) {
//    return 1 / (1 + std::exp(-x));
//}
template<typename T>
ArrayX<T>& sigmoid(const ArrayX<T>& x) {
    //return 1 / (1 + std::exp(-x));
    return (ArrayX<T>)inverse(exp(-x) + 1);
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
T logsumexp(const ArrayX<T>& vect) {

    return log(exp(vect).sum() + 2);

    //for (int i = 0; i < sz; ++i)
    //    sum += std::exp(vect[i]);
    //sum += 2;
    //return log(sum);
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
    // init eigen wrappers first
    //Map<const ArrayX<T>> map_alphas(alphas, k);
    Eigen::Map<const ArrayX<T>> forget;
    Eigen::Map<const ArrayX<T>> ingate;
    Eigen::Map<const ArrayX<T>> outgate;
    Eigen::Map<const ArrayX<T>> change;

    WeightOrBias(const T* params, int hsize)// :
        //forget(params, hsize), // DANGER maybe do resize and write then
        //ingate(&params[hsize], hsize),
        //outgate(&params[2 * hsize], hsize),
        //change(&params[3 * hsize], hsize)
    {
        //Map<const ArrayX<T>> _forget(params, hsize);
        //forget = _forget;
        //forget = Map<ArrayX<T>>(params, hsize);
        //forget = Map<Eigen::MatrixXd>(params, hsize);
        Eigen::Array<T, -1, 1> arr = Map<Eigen::Array<T, -1, 1>>(params, hsize);
        //forget.resize(hsize);
        //forget = Eigen::Map<const ArrayX<T>>(params, hsize);
        //Eigen::Map<const ArrayX<T>> forget(params, hsize);
        //Eigen::Map < const Eigen::Matrix< T, 1, char_bits, Eigen::RowMajor> >(&input_sequence[char_bits * i])
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
    //const T* in_weight;
    //const T* out_weight;
    //const T* out_bias;
    Eigen::Map<const ArrayX<T>> in_weight;
    Eigen::Map<const ArrayX<T>> out_weight;
    Eigen::Map<const ArrayX<T>> out_bias;

    ExtraParams(const T* params, int hsize) :
        in_weight(params, hsize),
        out_weight(&params[hsize], hsize),
        out_bias(&params[2 * hsize], hsize)
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
            //sequence.push_back(Eigen::Map < const Eigen::Matrix< T, 1, char_bits, Eigen::RowMajor> >(&input_sequence[char_bits * i]));
            ArrayX<T> arr(1, char_bits);
            for (int j = 0; j < char_bits; j++)
            {
                arr.row(0).col(j) << input_sequence[char_bits * i + j];
            }
            sequence.push_back(arr);
            //auto seq = &input_sequence[char_bits * i];
            //auto sequen = Eigen::Map<Eigen::Matrix<T, 1, 14> >(input_sequence[char_bits * i]);
            //sequence.push_back(Eigen::Map<Eigen::Matrix<T, 1, Eigen::Dynamic>>(&input_sequence[char_bits * i], 1, char_bits));
            //std::vector<T> buf(&input_sequence[char_bits * i], &input_sequence[char_bits * i] + char_bits);// = &input_sequence[char_bits * i];
            //ArrayX<T> arr = Eigen::Map<const ArrayX<T>>(&input_sequence[char_bits * i], 1, char_bits);//(buf, 1, char_bits);
            //sequence.push_back(arr); // ERROR some convertation problem here
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
    Eigen::Map<const ArrayX<T>> hidden;
    Eigen::Map<const ArrayX<T>> cell;

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
    ArrayX<T> forget = sigmoid((ArrayX<T>)(input * params.weight.forget + params.bias.forget));
    ArrayX<T> ingate = sigmoid((ArrayX<T>)(state.hidden * params.weight.ingate + params.bias.ingate));
    ArrayX<T> outgate = sigmoid((ArrayX<T>)(input * params.weight.outgate + params.bias.outgate));
    ArrayX<T> change = tanh(state.hidden * params.weight.change + params.bias.change);

    state.cell = state.cell * forget + ingate * change;
    state.hidden = outgate * tanh(state.cell);
}

// Predict LSTM output given an input
template<typename T>
void lstm_predict(int l, int b,
    const MainParams<T>& main_params, const ExtraParams<T>& extra_params,
    State<T>& state,
    const ArrayX<T>& input, ArrayX<T>& output)
    //void lstm_predict(int l, int b,
    //    const MainParams<T>& main_params, const ExtraParams<T>& extra_params,
    //    State<T>& state,
    //    const T* input, T* output)
{
    //for (int i = 0; i < b; ++i)
    //    output[i] = input[i] * extra_params.in_weight[i];
    output = input * (ArrayX<T>)extra_params.in_weight; // DANGER types may be incompatible

    //T* layer_output = output;
    ArrayX<T> layer_output = output;

    for (int i = 0; i < l; ++i)
    {
        lstm_model(b, main_params.layer_params[i], state.layer_state[i], layer_output);
        layer_output = state.layer_state[i].hidden;
    }

    //for (int i = 0; i < b; ++i)
    //    output[i] = layer_output[i] * extra_params.out_weight[i] + extra_params.out_bias[i];
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

        //T lse = logsumexp(ypred.data(), b);
        //for (int i = 0; i < b; ++i)
        //    ynorm[i] = ypred[i] - lse;
        ynorm = ypred - logsumexp(ypred);//log(sum(exp(ypred), 2))

        //const T* ygold = sequence_wrap.sequence[t + 1];
        const ArrayX<T> ygold = sequence_wrap.sequence[t + 1];
        total += (ygold * ynorm).sum();
        //for (int i = 0; i < b; ++i)
        //    total += ygold[i] * ynorm[i];

        count += b;
    }

    *loss = -total / count;
}

//*******|||||||||||||||||||||||||||||||||*************
//*****************************************************
//*******|||||||||||||||||||||||||||||||||*************
*/