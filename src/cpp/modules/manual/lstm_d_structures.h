// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once

#include <vector>

template<typename T>
struct StatePartWeightOrBiasDerivatives
{
    T forget;
    T ingate;
    T outgate;
    T change;
};

template<typename T>
struct StateElementGradientModel
{
    // 4 corresponding non-zero derivatives
    StatePartWeightOrBiasDerivatives<T> d_weight;
    // 4 corresponding non-zero derivatives
    StatePartWeightOrBiasDerivatives<T> d_bias;
    // a single corresponding non-zero derivative
    T d_hidden;
    // a single corresponding non-zero derivative
    T d_cell;
    // a single corresponding non-zero derivative
    T d_input;
};

template<typename T>
struct ModelJacobian
{
    std::vector<StateElementGradientModel<T>> hidden;
    std::vector<StateElementGradientModel<T>> cell;

    ModelJacobian(int hsize) :
        hidden(hsize),
        cell(hsize)
    {}
};

template<typename T>
struct StateElementGradientPredict
{
    // n_layers derivatives by corresponding weights from all layers
    T* d_weight_forget;
    // n_layers derivatives by corresponding weights from all layers
    T* d_weight_ingate;
    // n_layers derivatives by corresponding weights from all layers
    T* d_weight_outgate;
    // n_layers derivatives by corresponding weights from all layers
    T* d_weight_change;
    // n_layers derivatives by corresponding biases from all layers
    T* d_bias_forget;
    // n_layers derivatives by corresponding biases from all layers
    T* d_bias_ingate;
    // n_layers derivatives by corresponding biases from all layers
    T* d_bias_outgate;
    // n_layers derivatives by corresponding biases from all layers
    T* d_bias_change;
    // n_layers derivatives by corresponding hidden values from previous state from all layers
    T* d_hidden;
    // n_layers derivatives by corresponding cell values from previous state from all layers
    T* d_cell;
    // 1 derivative by the corresponding weight from extra params
    T* d_extra_in_weight;

    // raw_gradient must point to (10 * n_layers + 1) pre-allocated T
    StateElementGradientPredict(T* raw_gradient, int n_layers) :
        d_weight_forget(raw_gradient),
        d_weight_ingate(&raw_gradient[n_layers]),
        d_weight_outgate(&raw_gradient[2 * n_layers]),
        d_weight_change(&raw_gradient[3 * n_layers]),
        d_bias_forget(&raw_gradient[4 * n_layers]),
        d_bias_ingate(&raw_gradient[5 * n_layers]),
        d_bias_outgate(&raw_gradient[6 * n_layers]),
        d_bias_change(&raw_gradient[7 * n_layers]),
        d_hidden(&raw_gradient[8 * n_layers]),
        d_cell(&raw_gradient[9 * n_layers]),
        d_extra_in_weight(&raw_gradient[10 * n_layers])
    {}
};

template<typename T>
struct LayerStateJacobianPredict
{
    std::vector<StateElementGradientPredict<T>> d_hidden;
    std::vector<StateElementGradientPredict<T>> d_cell;
    T* raw_data;
    bool owns_memory;

    // raw_jacobian must point to ((10 * n_layers + 1) * 2 * hsize) pre-allocated T
    LayerStateJacobianPredict(T* raw_jacobian, int n_layers, int hsize, bool should_own_memory = false) :
        raw_data(raw_jacobian),
        owns_memory(should_own_memory)
    {
        d_hidden.reserve(hsize);
        d_cell.reserve(hsize);
        int gradient_size = 10 * n_layers + 1;
        for (int i = 0; i < hsize; ++i)
        {
            d_hidden.emplace_back(&raw_jacobian[i * gradient_size], n_layers);
            d_cell.emplace_back(&raw_jacobian[(i + hsize) * gradient_size], n_layers);
        }
    }

    LayerStateJacobianPredict(int n_layers, int hsize) :
        LayerStateJacobianPredict(new T[(10 * n_layers + 1) * 2 * hsize], n_layers, hsize, true)
    {}

    ~LayerStateJacobianPredict()
    {
        if (owns_memory)
            delete[] raw_data;
    }
};

template<typename T>
struct StateJacobianPredict
{
    std::vector<LayerStateJacobianPredict<T>> layer;
    T* raw_data;
    bool owns_memory;

    // raw_jacobian must point to (((10 * n_layers + 1) * 2 * hsize) * n_layers) pre-allocated T
    StateJacobianPredict(T* raw_jacobian, int n_layers, int hsize, bool should_own_memory = false) :
        raw_data(raw_jacobian),
        owns_memory(should_own_memory)
    {
        layer.reserve(n_layers);
        int layer_size = (10 * n_layers + 1) * 2 * hsize;
        for (int i = 0; i < n_layers; ++i)
        {
            layer.emplace_back(&raw_jacobian[i * layer_size], n_layers, hsize);
        }
    }

    StateJacobianPredict(int n_layers, int hsize) :
        StateJacobianPredict(new T[((10 * n_layers + 1) * 2 * hsize) * n_layers], n_layers, hsize, true)
    {}

    ~StateJacobianPredict()
    {
        if (owns_memory)
            delete[] raw_data;
    }
};

template<typename T>
struct PredictionElementGradient
{
    // n_layers derivatives by corresponding weights from all layers
    T* d_weight_forget;
    // n_layers derivatives by corresponding weights from all layers
    T* d_weight_ingate;
    // n_layers derivatives by corresponding weights from all layers
    T* d_weight_outgate;
    // n_layers derivatives by corresponding weights from all layers
    T* d_weight_change;
    // n_layers derivatives by corresponding biases from all layers
    T* d_bias_forget;
    // n_layers derivatives by corresponding biases from all layers
    T* d_bias_ingate;
    // n_layers derivatives by corresponding biases from all layers
    T* d_bias_outgate;
    // n_layers derivatives by corresponding biases from all layers
    T* d_bias_change;
    // n_layers derivatives by corresponding hidden values from previous state from all layers
    T* d_hidden;
    // n_layers derivatives by corresponding cell values from previous state from all layers
    T* d_cell;
    // 1 derivative by the corresponding weight from extra params
    T* d_extra_in_weight;
    // 1 derivative by the corresponding weight from extra params
    T* d_extra_out_weight;
    // 1 derivative by the corresponding bias from extra params
    T* d_extra_out_bias;

    // raw_gradient must point to (10 * n_layers + 3) pre-allocated T
    PredictionElementGradient(T* raw_gradient, int n_layers) :
        d_weight_forget(raw_gradient),
        d_weight_ingate(&raw_gradient[n_layers]),
        d_weight_outgate(&raw_gradient[2 * n_layers]),
        d_weight_change(&raw_gradient[3 * n_layers]),
        d_bias_forget(&raw_gradient[4 * n_layers]),
        d_bias_ingate(&raw_gradient[5 * n_layers]),
        d_bias_outgate(&raw_gradient[6 * n_layers]),
        d_bias_change(&raw_gradient[7 * n_layers]),
        d_hidden(&raw_gradient[8 * n_layers]),
        d_cell(&raw_gradient[9 * n_layers]),
        d_extra_in_weight(&raw_gradient[10 * n_layers]),
        d_extra_out_weight(&raw_gradient[10 * n_layers + 1]),
        d_extra_out_bias(&raw_gradient[10 * n_layers + 2])
    {}
};

template<typename T>
struct PredictionJacobian
{
    std::vector<PredictionElementGradient<T>> d_prediction;
    T* raw_data;
    bool owns_memory;

    // raw_jacobian must point to ((10 * n_layers + 3) * hsize) pre-allocated T
    PredictionJacobian(T* raw_jacobian, int n_layers, int hsize, bool should_own_memory = false) :
        raw_data(raw_jacobian),
        owns_memory(should_own_memory)
    {
        d_prediction.reserve(hsize);
        int gradient_size = 10 * n_layers + 3;
        for (int i = 0; i < hsize; ++i)
        {
            d_prediction.emplace_back(&raw_jacobian[i * gradient_size], n_layers);
        }
    }

    PredictionJacobian(int n_layers, int hsize) :
        PredictionJacobian(new T[(10 * n_layers + 3) * hsize], n_layers, hsize, true)
    {}

    ~PredictionJacobian()
    {
        if (owns_memory)
            delete[] raw_data;
    }
};

template<typename T>
struct GradByWeightOrBias
{
    T* forget;
    T* ingate;
    T* outgate;
    T* change;

    GradByWeightOrBias(T* grad_raw, int hsize) :
        forget(grad_raw),
        ingate(&grad_raw[hsize]),
        outgate(&grad_raw[2 * hsize]),
        change(&grad_raw[3 * hsize])
    {}
};

template<typename T>
struct GradByLayerParams
{
    GradByWeightOrBias<T> d_weight;
    GradByWeightOrBias<T> d_bias;

    GradByLayerParams(T* grad_raw, int hsize) :
        d_weight(grad_raw, hsize),
        d_bias(&grad_raw[hsize * 4], hsize)
    {}
};

template<typename T>
struct GradByParams
{
    std::vector<GradByLayerParams<T>> layer;
    T* d_in_weight;
    T* d_out_weight;
    T* d_out_bias;
    T* raw_data;
    bool owns_memory;

    // raw_jacobian must point to (8 * n_layers * hsize + 3 * hsize) pre-allocated T
    GradByParams(T* grad_raw, int n_layers, int hsize, bool should_own_memory = false) :
        raw_data(grad_raw),
        owns_memory(should_own_memory),
        d_in_weight(&grad_raw[8 * hsize * n_layers]),
        d_out_weight(&grad_raw[8 * hsize * n_layers + hsize]),
        d_out_bias(&grad_raw[8 * hsize * n_layers + 2 * hsize])
    {
        layer.reserve(n_layers);
        for (int i = 0; i < n_layers; ++i)
        {
            layer.emplace_back(&grad_raw[8 * hsize * i], hsize);
        }
    }

    GradByParams(int n_layers, int hsize) :
        GradByParams(new T[8 * n_layers * hsize + 3 * hsize], n_layers, hsize, true)
    {}

    ~GradByParams()
    {
        if (owns_memory)
            delete[] raw_data;
    }
};