#pragma once

#include <vector>

#include "lstm_eigen_helpers.h"

//template<typename T>
//struct StatePartWeightOrBiasDerivatives
//{
//    T forget;
//    T ingate;
//    T outgate;
//    T change;
//};
//
//template<typename T>
//struct StateElementGradientModel
//{
//    // 4 corresponding non-zero derivatives
//    StatePartWeightOrBiasDerivatives<T> d_weight;
//    // 4 corresponding non-zero derivatives
//    StatePartWeightOrBiasDerivatives<T> d_bias;
//    // a single corresponding non-zero derivative
//    T d_hidden;
//    // a single corresponding non-zero derivative
//    T d_cell;
//    // a single corresponding non-zero derivative
//    T d_input;
//};
//
//template<typename T>
//struct ModelJacobian
//{
//    std::vector<StateElementGradientModel<T>> hidden;
//    std::vector<StateElementGradientModel<T>> cell;
//
//    ModelJacobian(int hsize) :
//        hidden(hsize),
//        cell(hsize)
//    {}
//};

template<typename T>
struct StatePartWeightOrBiasDerivatives
{
    MapX<T> forget;
    MapX<T> ingate;
    MapX<T> outgate;
    MapX<T> change;

    StatePartWeightOrBiasDerivatives(T* raw_model, int hsize) :
        forget(raw_model, hsize),
        ingate(&raw_model[hsize], hsize),
        outgate(&raw_model[2 * hsize], hsize),
        change(&raw_model[3 * hsize], hsize)
    {}
};


template<typename T>
struct StateElementGradientModel
{
    // 4 corresponding non-zero derivatives
    StatePartWeightOrBiasDerivatives<T> d_weight;
    // 4 corresponding non-zero derivatives
    StatePartWeightOrBiasDerivatives<T> d_bias;
    // an array corresponding non-zero derivatives
    MapX<T> d_hidden;
    // an array corresponding non-zero derivatives
    MapX<T> d_cell;
    // an array corresponding non-zero derivatives
    MapX<T> d_input;

    StateElementGradientModel(T* raw_model, int hsize) :
        d_weight(raw_model, hsize),
        d_bias(&raw_model[4 * hsize], hsize),
        d_hidden(&raw_model[8 * hsize], hsize),
        d_cell(&raw_model[9 * hsize], hsize),
        d_input(&raw_model[10 * hsize], hsize)
    {}
};

template<typename T>
struct ModelJacobian
{
    StateElementGradientModel<T> hidden;
    StateElementGradientModel<T> cell;
    T* raw_data;
    bool owns_memory;

    // raw_jacobian must point to (11 * 2 * hsize) pre-allocated T
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
struct StateElementGradientModelNew
{
    // Matrix(hsize, 10) derivatives from all layers
    MapX10<T> d_rawX10;
    // array of corresponding non-zero derivatives
    MapX<T> d_input;

    StateElementGradientModelNew(T* raw_data, int hsize) :
        d_rawX10(raw_data, hsize, 10),
        d_input(&raw_data[10 * hsize], hsize)
    {}
};

template<typename T>
struct ModelJacobianNew
{
    StateElementGradientModelNew<T> hidden;
    StateElementGradientModelNew<T> cell;
    T* raw_data;
    bool owns_memory;

    ModelJacobianNew(T* raw_model, int hsize, bool should_own_memory = false) :
        owns_memory(should_own_memory),
        raw_data(raw_model),
        hidden(raw_model, hsize),
        cell(&raw_model[11 * hsize], hsize)
    {}

    ModelJacobianNew(int hsize) :
        ModelJacobianNew(new T[11 * 2 * hsize], hsize, true)
    {}

    ~ModelJacobianNew()
    {
        if (owns_memory)
            delete[] raw_data;
    }
};

template<typename T>
struct StateElementGradientPredictNew
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
    StateElementGradientPredictNew(T* raw_gradient, int n_layers) :
        d_rawX8(raw_gradient, n_layers, 8),
        d_rawX10(raw_gradient, n_layers, 10),
        d_hidden(&raw_gradient[8 * n_layers], n_layers),
        d_cell(&raw_gradient[9 * n_layers], n_layers),
        d_extra_in_weight(&raw_gradient[10 * n_layers])
    {}
};

template<typename T>
struct LayerStateJacobianPredictNew
{
    std::vector<StateElementGradientPredictNew<T>> d_hidden;
    std::vector<StateElementGradientPredictNew<T>> d_cell;
    T* raw_data;
    bool owns_memory;

    // raw_jacobian must point to ((10 * n_layers + 1) * 2 * hsize) pre-allocated T
    LayerStateJacobianPredictNew(T* raw_jacobian, int n_layers, int hsize, bool should_own_memory = false) :
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

    LayerStateJacobianPredictNew(int n_layers, int hsize) :
        LayerStateJacobianPredictNew(new T[(10 * n_layers + 1) * 2 * hsize], n_layers, hsize, true)
    {}

    ~LayerStateJacobianPredictNew()
    {
        if (owns_memory)
            delete[] raw_data;
    }
};

template<typename T>
struct StateJacobianPredictNew
{
    std::vector<LayerStateJacobianPredictNew<T>> layer;
    T* raw_data;
    bool owns_memory;

    // raw_jacobian must point to (((10 * n_layers + 1) * 2 * hsize) * n_layers) pre-allocated T
    StateJacobianPredictNew(T* raw_jacobian, int n_layers, int hsize, bool should_own_memory = false) :
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

    StateJacobianPredictNew(int n_layers, int hsize) :
        StateJacobianPredictNew(new T[((10 * n_layers + 1) * 2 * hsize) * n_layers], n_layers, hsize, true)
    {}

    ~StateJacobianPredictNew()
    {
        if (owns_memory)
            delete[] raw_data;
    }
};

template<typename T>
struct PredictionElementGradientNew
{
    // Matrix(n_layers, 8) derivatives from all layers
    MapX8<T> d_rawX8;
    // Matrix(n_layers, 10) derivatives from all layers
    MapX10<T> d_rawX10;
    // n_layers derivatives by corresponding hidden values from previous state from all layers
    MapX<T> d_hidden;
    // n_layers derivatives by corresponding cell values from previous state from all layers
    MapX<T> d_cell;
    // d_extra_in_out
    MapRow3<T> d_extra_in_out;
    // 1 derivative by the corresponding weight from extra params
    T* d_extra_in_weight;
    // 1 derivative by the corresponding weight from extra params
    T* d_extra_out_weight;
    // 1 derivative by the corresponding bias from extra params
    T* d_extra_out_bias;

    // raw_gradient must point to (10 * n_layers + 3) pre-allocated T
    PredictionElementGradientNew(T* raw_gradient, int n_layers) :
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
struct PredictionJacobianNew
{
    std::vector<PredictionElementGradientNew<T>> d_prediction;
    T* raw_data;
    bool owns_memory;

    // raw_jacobian must point to ((10 * n_layers + 3) * hsize) pre-allocated T
    PredictionJacobianNew(T* raw_jacobian, int n_layers, int hsize, bool should_own_memory = false) :
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

    PredictionJacobianNew(int n_layers, int hsize) :
        PredictionJacobianNew(new T[(10 * n_layers + 3) * hsize], n_layers, hsize, true)
    {}

    ~PredictionJacobianNew()
    {
        if (owns_memory)
            delete[] raw_data;
    }
};

template<typename T>
struct GradByLayerParamsNew
{
    // Matrix(n_layers, 8) derivatives for all params
    MapX8<T> d_params;

    // grad_raw must point to (8 * hsize) pre-allocated T
    GradByLayerParamsNew(T* grad_raw, int hsize) :
        d_params(grad_raw, hsize, 8)
    {}
};

template<typename T>
struct GradByParamsNew
{
    std::vector<GradByLayerParamsNew<T>> layer;
    MapX3<T> d_in_out;
    T* raw_data;
    bool owns_memory;

    // raw_jacobian must point to (8 * n_layers * hsize + 3 * hsize) pre-allocated T
    GradByParamsNew(T* grad_raw, int n_layers, int hsize, bool should_own_memory = false) :
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

    GradByParamsNew(int n_layers, int hsize) :
        GradByParamsNew(new T[8 * n_layers * hsize + 3 * hsize], n_layers, hsize, true)
    {}

    ~GradByParamsNew()
    {
        if (owns_memory)
            delete[] raw_data;
    }
};