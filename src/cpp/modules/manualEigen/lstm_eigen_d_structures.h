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
        d_rawX10(raw_data, hsize, 10),//, Eigen::Stride<Eigen::Dynamic, 1>(hsize, 1)), // DANGER maybe need to change to colmajor
        //d_raw(Map<MapX10<T>, hsize, 10, Eigen::Stride<> >(raw_data, hsize, 10, Eigen::Stride<14, 1>)),
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

    //ModelJacobianNew(int hsize) :
    //    hidden(hsize),
    //    cell(hsize)
    //{}

    ModelJacobianNew(ModelJacobian<T>& model_jacobian, int hsize)
    {
        this->hidden.d_raw.resize(hsize, 10);
        this->cell.d_raw.resize(hsize, 10);

        this->hidden.d_raw.col(0) = model_jacobian.hidden.d_weight.forget;
        this->hidden.d_raw.col(1) = model_jacobian.hidden.d_weight.ingate;
        this->hidden.d_raw.col(2) = model_jacobian.hidden.d_weight.outgate;
        this->hidden.d_raw.col(3) = model_jacobian.hidden.d_weight.change;
        this->hidden.d_raw.col(4) = model_jacobian.hidden.d_bias.forget;
        this->hidden.d_raw.col(5) = model_jacobian.hidden.d_bias.ingate;
        this->hidden.d_raw.col(6) = model_jacobian.hidden.d_bias.outgate;
        this->hidden.d_raw.col(7) = model_jacobian.hidden.d_bias.change;
        this->hidden.d_raw.col(8) = model_jacobian.hidden.d_hidden;
        this->hidden.d_raw.col(9) = model_jacobian.hidden.d_cell;
        this->hidden.d_input = model_jacobian.hidden.d_input;

        this->cell.d_raw.col(0) = model_jacobian.cell.d_weight.forget;
        this->cell.d_raw.col(1) = model_jacobian.cell.d_weight.ingate;
        this->cell.d_raw.col(2) = model_jacobian.cell.d_weight.outgate;
        this->cell.d_raw.col(3) = model_jacobian.cell.d_weight.change;
        this->cell.d_raw.col(4) = model_jacobian.cell.d_bias.forget;
        this->cell.d_raw.col(5) = model_jacobian.cell.d_bias.ingate;
        this->cell.d_raw.col(6) = model_jacobian.cell.d_bias.outgate;
        this->cell.d_raw.col(7) = model_jacobian.cell.d_bias.change;
        this->cell.d_raw.col(8) = model_jacobian.cell.d_hidden;
        this->cell.d_raw.col(9) = model_jacobian.cell.d_cell;
        this->cell.d_input << model_jacobian.cell.d_input;
    }

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
struct StateElementGradientPredict
{
    // n_layers derivatives by corresponding weights from all layers
    MapX<T> d_weight_forget;
    // n_layers derivatives by corresponding weights from all layers
    MapX<T> d_weight_ingate;
    // n_layers derivatives by corresponding weights from all layers
    MapX<T> d_weight_outgate;
    // n_layers derivatives by corresponding weights from all layers
    MapX<T> d_weight_change;
    // n_layers derivatives by corresponding biases from all layers
    MapX<T> d_bias_forget;
    // n_layers derivatives by corresponding biases from all layers
    MapX<T> d_bias_ingate;
    // n_layers derivatives by corresponding biases from all layers
    MapX<T> d_bias_outgate;
    // n_layers derivatives by corresponding biases from all layers
    MapX<T> d_bias_change;
    // n_layers derivatives by corresponding hidden values from previous state from all layers
    MapX<T> d_hidden;
    // n_layers derivatives by corresponding cell values from previous state from all layers
    MapX<T> d_cell;
    // 1 derivative by the corresponding weight from extra params
    T* d_extra_in_weight;

    // raw_gradient must point to (10 * n_layers + 1) pre-allocated T
    StateElementGradientPredict(T* raw_gradient, int n_layers) :
        d_weight_forget(raw_gradient, n_layers),
        d_weight_ingate(&raw_gradient[n_layers], n_layers),
        d_weight_outgate(&raw_gradient[2 * n_layers], n_layers),
        d_weight_change(&raw_gradient[3 * n_layers], n_layers),
        d_bias_forget(&raw_gradient[4 * n_layers], n_layers),
        d_bias_ingate(&raw_gradient[5 * n_layers], n_layers),
        d_bias_outgate(&raw_gradient[6 * n_layers], n_layers),
        d_bias_change(&raw_gradient[7 * n_layers], n_layers),
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
struct StateElementGradientPredictNew
{
    // Matrix(n_layers, 8) derivatives from all layers
    MapX8<T> d_rawX8;
    // Matrix(n_layers, 10) derivatives from all layers
    MapX10<T> d_rawX10;
    //
    MapX<T> d_hidden;
    //
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
struct PredictionElementGradient
{
    // n_layers derivatives by corresponding weights from all layers
    MapX<T> d_weight_forget;
    // n_layers derivatives by corresponding weights from all layers
    MapX<T> d_weight_ingate;
    // n_layers derivatives by corresponding weights from all layers
    MapX<T> d_weight_outgate;
    // n_layers derivatives by corresponding weights from all layers
    MapX<T> d_weight_change;
    // n_layers derivatives by corresponding biases from all layers
    MapX<T> d_bias_forget;
    // n_layers derivatives by corresponding biases from all layers
    MapX<T> d_bias_ingate;
    // n_layers derivatives by corresponding biases from all layers
    MapX<T> d_bias_outgate;
    // n_layers derivatives by corresponding biases from all layers
    MapX<T> d_bias_change;
    // n_layers derivatives by corresponding hidden values from previous state from all layers
    MapX<T> d_hidden;
    // n_layers derivatives by corresponding cell values from previous state from all layers
    MapX<T> d_cell;
    // 1 derivative by the corresponding weight from extra params
    T* d_extra_in_weight;
    // 1 derivative by the corresponding weight from extra params
    T* d_extra_out_weight;
    // 1 derivative by the corresponding bias from extra params
    T* d_extra_out_bias;

    // raw_gradient must point to (10 * n_layers + 3) pre-allocated T
    PredictionElementGradient(T* raw_gradient, int n_layers) :
        d_weight_forget(raw_gradient, n_layers),
        d_weight_ingate(&raw_gradient[n_layers], n_layers),
        d_weight_outgate(&raw_gradient[2 * n_layers], n_layers),
        d_weight_change(&raw_gradient[3 * n_layers], n_layers),
        d_bias_forget(&raw_gradient[4 * n_layers], n_layers),
        d_bias_ingate(&raw_gradient[5 * n_layers], n_layers),
        d_bias_outgate(&raw_gradient[6 * n_layers], n_layers),
        d_bias_change(&raw_gradient[7 * n_layers], n_layers),
        d_hidden(&raw_gradient[8 * n_layers], n_layers),
        d_cell(&raw_gradient[9 * n_layers], n_layers),
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
struct PredictionElementGradientNew
{
    // Matrix(n_layers, 8) derivatives from all layers
    MapX8<T> d_rawX8;
    //
    MapX<T> d_hidden;
    //
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
struct GradByWeightOrBias
{
    MapX<T> forget;
    MapX<T> ingate;
    MapX<T> outgate;
    MapX<T> change;

    GradByWeightOrBias(T* grad_raw, int hsize) :
        forget(grad_raw, hsize),
        ingate(&grad_raw[hsize], hsize),
        outgate(&grad_raw[2 * hsize], hsize),
        change(&grad_raw[3 * hsize], hsize)
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
    MapX<T> d_in_weight;
    MapX<T> d_out_weight;
    MapX<T> d_out_bias;
    T* raw_data;
    bool owns_memory;

    // raw_jacobian must point to (8 * n_layers * hsize + 3 * hsize) pre-allocated T
    GradByParams(T* grad_raw, int n_layers, int hsize, bool should_own_memory = false) :
        raw_data(grad_raw),
        owns_memory(should_own_memory),
        d_in_weight(&grad_raw[8 * hsize * n_layers], hsize),
        d_out_weight(&grad_raw[8 * hsize * n_layers + hsize], hsize),
        d_out_bias(&grad_raw[8 * hsize * n_layers + 2 * hsize], hsize)
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

template<typename T>
struct GradByLayerParamsNew
{
    MapX8<T> d_params;

    // grad_raw contains 8*hsize preallocated data
    GradByLayerParamsNew(T* grad_raw, int hsize) :
        d_params(grad_raw, hsize, 8)
    {}
};

template<typename T>
struct GradByParamsNew
{
    std::vector<GradByLayerParamsNew<T>> layer;
    MapX3<T> d_in_out;
    //MapX<T> d_in_weight;
    //MapX<T> d_out_weight;
    //MapX<T> d_out_bias;
    T* raw_data;
    bool owns_memory;

    // raw_jacobian must point to (8 * n_layers * hsize + 3 * hsize) pre-allocated T
    GradByParamsNew(T* grad_raw, int n_layers, int hsize, bool should_own_memory = false) :
        raw_data(grad_raw),
        owns_memory(should_own_memory),
        d_in_out(&grad_raw[8 * hsize * n_layers], hsize, 3)
        //d_in_weight(&grad_raw[8 * hsize * n_layers], hsize),
        //d_out_weight(&grad_raw[8 * hsize * n_layers + hsize], hsize),
        //d_out_bias(&grad_raw[8 * hsize * n_layers + 2 * hsize], hsize)
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