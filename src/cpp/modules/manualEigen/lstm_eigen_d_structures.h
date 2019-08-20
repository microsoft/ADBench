#pragma once

#include <vector>

#include "../../shared/lstm_eigen_types.h"

// To simlify eigen operations and reduce the amount of code
// here used special maps of matrices with X rows and 8 or 10 cols:

// d_rawX8 is a map of matrix which contains (by cols):
// d_weight_forget  - n_layers derivatives by corresponding weights from all layers
// d_weight_ingate  - n_layers derivatives by corresponding weights from all layers
// d_weight_outgate - n_layers derivatives by corresponding weights from all layers
// d_weight_change  - n_layers derivatives by corresponding weights from all layers
// d_bias_forget    - n_layers derivatives by corresponding biases from all layers
// d_bias_ingate    - n_layers derivatives by corresponding biases from all layers
// d_bias_outgate   - n_layers derivatives by corresponding biases from all layers
// d_bias_change    - n_layers derivatives by corresponding biases from all layers

// d_rawX10 in addition contains two more vectors (by cols):
// d_hidden         - n_layers derivatives by corresponding hidden values from previous state from all layers
// d_cell           - n_layers derivatives by corresponding cell values from previous state from all layers


template<typename T>
struct StateElementGradientModel
{
    // Matrix(hsize, 10) derivatives from all layers
    MapX10<T> d_rawX10;
    // hsize derivatives by corresponding weights from all layers
    MapX<T> d_weight_forget;
    // hsize derivatives by corresponding weights from all layers
    MapX<T> d_weight_ingate;
    // hsize derivatives by corresponding weights from all layers
    MapX<T> d_weight_outgate;
    // hsize derivatives by corresponding weights from all layers
    MapX<T> d_weight_change;
    // hsize derivatives by corresponding biases from all layers
    MapX<T> d_bias_forget;
    // hsize derivatives by corresponding biases from all layers
    MapX<T> d_bias_ingate;
    // hsize derivatives by corresponding biases from all layers
    MapX<T> d_bias_outgate;
    // hsize derivatives by corresponding biases from all layers
    MapX<T> d_bias_change;
    // hsize derivatives by corresponding hidden values from previous state from all layers
    MapX<T> d_hidden;
    // hsize derivatives by corresponding cell values from previous state from all layers
    MapX<T> d_cell;
    // hsize derivatives of corresponding input values
    MapX<T> d_input;

    // raw_data must point to (11 * hsize) pre-allocated T
    StateElementGradientModel(T* raw_data, int hsize) :
        d_rawX10(raw_data, hsize, 10),
        d_weight_forget(raw_data, hsize),
        d_weight_ingate(&raw_data[hsize], hsize),
        d_weight_outgate(&raw_data[2 * hsize], hsize),
        d_weight_change(&raw_data[3 * hsize], hsize),
        d_bias_forget(&raw_data[4 * hsize], hsize),
        d_bias_ingate(&raw_data[5 * hsize], hsize),
        d_bias_outgate(&raw_data[6 * hsize], hsize),
        d_bias_change(&raw_data[7 * hsize], hsize),
        d_hidden(&raw_data[8 * hsize], hsize),
        d_cell(&raw_data[9 * hsize], hsize),
        d_input(&raw_data[10 * hsize], hsize)
    {}
};

template<typename T>
struct ModelJacobian
{
    StateElementGradientModel<T> hidden;
    StateElementGradientModel<T> cell;
    T* raw_data;
    bool owns_memory;

    // raw_model must point to (11 * 2 * hsize) pre-allocated T
    ModelJacobian(T* raw_model, int hsize, bool should_own_memory = false) :
        owns_memory(should_own_memory),
        raw_data(raw_model),
        hidden(raw_model, hsize),
        cell(&raw_model[11 * hsize], hsize)
    {}

    ModelJacobian(int hsize) :
        ModelJacobian(new T[11 * 2 * hsize], hsize, true)
    {}

    ~ModelJacobian()
    {
        if (owns_memory)
            delete[] raw_data;
    }
};

template<typename T>
struct StateElementGradientPredict
{
    // Matrix(n_layers, 8) derivatives from all layers
    MapX8<T> d_rawX8;
    // Matrix(n_layers, 10) derivatives from all layers
    MapX10<T> d_rawX10;
    // n_layers derivatives by corresponding hidden values from previous state from all layers
    MapX<T> d_hidden;
    // n_layers derivatives by corresponding cell values from previous state from all layers
    MapX<T> d_cell;
    // 1 derivative by the corresponding weight from extra params
    T* d_extra_in_weight;

    // raw_gradient must point to (10 * n_layers + 1) pre-allocated T
    StateElementGradientPredict(T* raw_gradient, int n_layers) :
        d_rawX8(raw_gradient, n_layers, 8),
        d_rawX10(raw_gradient, n_layers, 10),
        d_hidden(&raw_gradient[8 * n_layers], n_layers),
        d_cell(&raw_gradient[9 * n_layers], n_layers),
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
        owns_memory(should_own_memory),
        raw_data(raw_jacobian)
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
    // Matrix(n_layers, 8) derivatives from all layers
    MapX8<T> d_rawX8;
    // Matrix(n_layers, 10) derivatives from all layers
    MapX10<T> d_rawX10;
    // n_layers derivatives by corresponding hidden values from previous state from all layers
    MapX<T> d_hidden;
    // n_layers derivatives by corresponding cell values from previous state from all layers
    MapX<T> d_cell;
    // 3 derivatives by the corresponding weight and bias from extra params
    MapRow3<T> d_extra_in_out;
    // 1 derivative by the corresponding weight from extra params
    T* d_extra_in_weight;
    // 1 derivative by the corresponding weight from extra params
    T* d_extra_out_weight;
    // 1 derivative by the corresponding bias from extra params
    T* d_extra_out_bias;

    // raw_gradient must point to (10 * n_layers + 3) pre-allocated T
    PredictionElementGradient(T* raw_gradient, int n_layers) :
        d_rawX8(raw_gradient, n_layers, 8),
        d_rawX10(raw_gradient, n_layers, 10),
        d_hidden(&raw_gradient[8 * n_layers], n_layers),
        d_cell(&raw_gradient[9 * n_layers], n_layers),
        d_extra_in_out(&raw_gradient[10 * n_layers]),
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
struct GradByLayerParams
{
    // Matrix(n_layers, 8) derivatives for all params
    MapX8<T> d_rawX8;

    // grad_raw must point to (8 * hsize) pre-allocated T
    GradByLayerParams(T* grad_raw, int hsize) :
        d_rawX8(grad_raw, hsize, 8)
    {}
};

template<typename T>
struct GradByParams
{
    std::vector<GradByLayerParams<T>> layer;
    // Matrix contains X rows and 3 cols
    // by cols: d_in_weight, d_out_weight & d_out_bias
    MapX3<T> d_in_out;
    T* raw_data;
    bool owns_memory;

    // raw_jacobian must point to (8 * n_layers * hsize + 3 * hsize) pre-allocated T
    GradByParams(T* grad_raw, int n_layers, int hsize, bool should_own_memory = false) :
        raw_data(grad_raw),
        owns_memory(should_own_memory),
        d_in_out(&grad_raw[8 * hsize * n_layers], hsize, 3)
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