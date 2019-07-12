#include "lstm_d.h"
#include "../../shared/lstm.h"

#include <vector>

// Helper structures

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

    // raw_jacobian must point to ((10 * n_layers + 1) * hsize) pre-allocated T
    LayerStateJacobianPredict(T* raw_jacobian, int n_layers, int hsize)
    {
        d_hidden.reserve(hsize);
        d_cell.reserve(hsize);
        int gradient_size = 10 * n_layers + 1;
        for (int i = 0; i < hsize; ++i)
        {
            d_hidden.emplace_back(&raw_jacobian[i * gradient_size], n_layers);
            d_cell.emplace_back(&raw_jacobian[i * gradient_size], n_layers);
        }
    }
};

template<typename T>
struct StateJacobianPredict
{
    std::vector<LayerStateJacobianPredict<T>> layer;

    // raw_jacobian must point to (((10 * n_layers + 1) * hsize) * n_layers) pre-allocated T
    StateJacobianPredict(T* raw_jacobian, int n_layers, int hsize)
    {
        layer.reserve(n_layers);
        int layer_size = (10 * n_layers + 1) * hsize;
        for (int i = 0; i < n_layers; ++i)
        {
            layer.emplace_back(&raw_jacobian[i * layer_size], n_layers, hsize);
        }
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

    // raw_jacobian must point to ((10 * n_layers + 3) * hsize) pre-allocated T
    PredictionJacobian(T* raw_jacobian, int n_layers, int hsize)
    {
        d_prediction.reserve(hsize);
        int gradient_size = 10 * n_layers + 3;
        for (int i = 0; i < hsize; ++i)
        {
            d_prediction.emplace_back(&raw_jacobian[i * gradient_size], n_layers);
        }
    }
};

// UTILS

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

// value (returned) and gradient (written to J) of log(sum(exp(x), 2))
template<typename T>
T logsumexp_d(const T* const vect, int sz, T* J) {
    for (int i = 0; i < sz; i++) J[i] = exp(vect[i]);
    T sum = 0.0;
    for (int i = 0; i < sz; i++) sum += J[i];
    sum += 2.;

    for (int i = 0; i < sz; i++) J[i] /= sum;
    return log(sum);
}

template<typename T>
void swap(StateJacobianPredict<T>& j1, StateJacobianPredict<T>& j2)
{
    j1.layer.swap(j2.layer);
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
    const LayerParams<T>& params,
    LayerState<T>& state,
    const T* input,
    ModelJacobian<T>& jacobian)
{
    // hidden and cell (outputs)
    // wrt weight, bias, hidden, cell, input
    //T* hidden_dw = &hidden_d_all[0];
    //T* hidden_db = &hidden_d_all[4 * hsize * hsize];
    //T* hidden_dh = &hidden_d_all[8 * hsize * hsize];
    //T* hidden_dc = &hidden_d_all[8 * hsize * hsize + hsize];
    //T* hidden_di = &hidden_d_all[8 * hsize * hsize + 2 * hsize];
    //T* cell_dw = &cell_d_all[0];
    //T* cell_db = &cell_d_all[4 * hsize * hsize];
    //T* cell_dh = &cell_d_all[8 * hsize * hsize];
    //T* cell_dc = &cell_d_all[8 * hsize * hsize + hsize];
    //T* cell_di = &cell_d_all[8 * hsize * hsize + 2 * hsize];
    // dw and db are full J matrices
    // but dh, dc, di are just vectors as cell[i]
    //	is only dependent on the ith term of
    //	each of these vectors

    for (int i = 0; i < hsize; i++) {
        // Only get relevant derivatives

        T forget_in = input[i] * params.weight.forget[i] + params.bias.forget[i];
        T forget = sigmoid(forget_in);
        T forget_sd = sigmoid_d(forget_in);
        T forget_dw = forget_sd * input[i];
        T forget_db = forget_sd;
        T forget_di = forget_sd * params.weight.forget[i];

        T ingate_in = state.hidden[i] * params.weight.ingate[i] + params.bias.ingate[i];
        T ingate = sigmoid(ingate_in);
        T ingate_sd = sigmoid_d(ingate_in);
        T ingate_dw = ingate_sd * state.hidden[i];
        T ingate_db = ingate_sd;
        T ingate_dh = ingate_sd * params.weight.ingate[i];

        T outgate_in = input[i] * params.weight.outgate[i] + params.bias.outgate[i];
        T outgate = sigmoid(outgate_in);
        T outgate_sd = sigmoid_d(outgate_in);
        T outgate_dw = outgate_sd * input[i];
        T outgate_db = outgate_sd;
        T outgate_di = outgate_sd * params.weight.outgate[i];

        T change_in = state.hidden[i] * params.weight.change[i] + params.bias.change[i];
        T change = tanh(change_in);
        T change_td = tanh_d(change_in);
        T change_dw = change_td * state.hidden[i];
        T change_db = change_td;
        T change_dh = change_td * params.weight.change[i];

        // Cell derivatives

        T orig_cell = state.cell[i];
        state.cell[i] = orig_cell * forget + ingate * change;
        // wrt weight
        jacobian.cell[i].d_weight.forget = orig_cell * forget_dw;
        jacobian.cell[i].d_weight.ingate = change * ingate_dw;
        jacobian.cell[i].d_weight.outgate = 0.;
        jacobian.cell[i].d_weight.change = ingate * change_dw;
        //cell_dw[i * 4 * hsize + i] = orig_cell * forget_dw;
        //cell_dw[i * 4 * hsize + hsize + i] = change * ingate_dw;
        //cell_dw[i * 4 * hsize + 3 * hsize + i] = ingate * change_dw;
        // wrt bias
        jacobian.cell[i].d_bias.forget = orig_cell * forget_db;
        jacobian.cell[i].d_bias.ingate = change * ingate_db;
        jacobian.cell[i].d_bias.outgate = 0.;
        jacobian.cell[i].d_bias.change = ingate * change_db;
        //cell_db[i * 4 * hsize + i] = orig_cell * forget_db;
        //cell_db[i * 4 * hsize + hsize + i] = change * ingate_db;
        //cell_db[i * 4 * hsize + 3 * hsize + i] = ingate * change_db;
        // wrt hidden, cell(original), input
        jacobian.cell[i].d_hidden = ingate * change_dh + change * ingate_dh;
        jacobian.cell[i].d_cell = forget;
        jacobian.cell[i].d_input = orig_cell * forget_di;
        //cell_dh[i] = ingate * change_dh + change * ingate_dh;
        //cell_dc[i] = forget;
        //cell_di[i] = orig_cell * forget_di;

        // Hidden derivatives

        T hidden_t = tanh(state.cell[i]);
        state.hidden[i] = outgate * hidden_t;
        T hidden_td = outgate * tanh_d(state.cell[i]);
        // wrt weight
        jacobian.hidden[i].d_weight.forget = hidden_td * jacobian.cell[i].d_weight.forget;
        jacobian.hidden[i].d_weight.ingate = hidden_td * jacobian.cell[i].d_weight.ingate;
        jacobian.hidden[i].d_weight.outgate = hidden_t * outgate_dw;
        jacobian.hidden[i].d_weight.change = hidden_td * jacobian.cell[i].d_weight.change;
        //hidden_dw[i * 4 * hsize + i] = hidden_td * cell_dw[i * 4 * hsize + i];
        //hidden_dw[i * 4 * hsize + hsize + i] = hidden_td * cell_dw[i * 4 * hsize + hsize + i];
        //hidden_dw[i * 4 * hsize + 2 * hsize + i] = hidden_t * outgate_dw;
        //hidden_dw[i * 4 * hsize + 3 * hsize + i] = hidden_td * cell_dw[i * 4 * hsize + 3 * hsize + i];
        // wrt bias
        jacobian.hidden[i].d_bias.forget = hidden_td * jacobian.cell[i].d_bias.forget;
        jacobian.hidden[i].d_bias.ingate = hidden_td * jacobian.cell[i].d_bias.ingate;
        jacobian.hidden[i].d_bias.outgate = hidden_t * outgate_db;
        jacobian.hidden[i].d_bias.change = hidden_td * jacobian.cell[i].d_bias.change;
        //hidden_db[i * 4 * hsize + i] = hidden_td * cell_db[i * 4 * hsize + i];
        //hidden_db[i * 4 * hsize + hsize + i] = hidden_td * cell_db[i * 4 * hsize + hsize + i];
        //hidden_db[i * 4 * hsize + 2 * hsize + i] = hidden_t * outgate_db;
        //hidden_db[i * 4 * hsize + 3 * hsize + i] = hidden_td * cell_db[i * 4 * hsize + 3 * hsize + i];
        // wrt hidden, cell (original), input
        jacobian.hidden[i].d_hidden = hidden_td * jacobian.cell[i].d_hidden;
        jacobian.hidden[i].d_cell = hidden_td * jacobian.cell[i].d_cell;
        jacobian.hidden[i].d_input = outgate_di * hidden_t + hidden_td * jacobian.cell[i].d_input;
        //hidden_dh[i] = hidden_td * cell_dh[i];
        //hidden_dc[i] = hidden_td * cell_dc[i];
        //hidden_di[i] = outgate_di * hidden_t + hidden_td * cell_di[i];
    }
}


// Manual derivative of lstm_predict
//	NOTE this is not finished
//	but eventually it should give derivatives of:
//	x2 and s (outputs)
//	w.r.t. w, w2 and s (inputs)
template<typename T>
void lstm_predict_d(int l, int b,
    const MainParams<T>& main_params, const ExtraParams<T>& extra_params,
    State<T>& state,
    const T* input, T* output,
    StateJacobianPredict<T>& state_jacobian,
    PredictionJacobian<T>& output_jacobian)
{
    //T* x2_d_w = &x2_d_all[0];
    // shape = (b, l, 4 * b)
    // 3-D array to represent x2 (vector) wrt w (matrix)
    //T* x2_d_w2 = &x2_d_all[8 * l * b * b];
    // x2 wrt w2
    // essentially 3 vectors, since each
    // x2[i] depends on w2[0, i], w2[1, i], w2[2, i]
    //T* x2_d_s = &x2_d_all[8 * l * b * b + 3 * b];

    //T* s_d_w = &s_d_all[0];
    //T* s_d_w2 = &s_d_all[8 * l * b * 2 * l * b];
    //T* s_d_s = &s_d_all[8 * l * b * 2 * l * b + 3 * b * 2 * l * b];

    //vector<T> x2_d_w2(3 * b);
    // x2 wrt w2
    // essentially 3 vectors, since each
    // x2[i] depends on w2[0, i], w2[1, i], w2[2, i]

    //vector<T> x2_d_w(b * 2 * l * 4 * b);
    // shape = (b, l, 4 * b)
    // 3-D array to represent x2 (vector) wrt w (matrix)

    std::vector<T> zero_layer_jacobian_raw((10 * l + 1) * b);
    LayerStateJacobianPredict<T> zero_layer_jacobian(zero_layer_jacobian_raw.data(), l, b);
    // Intial setup (from predict())
    for (int i = 0; i < b; ++i) {
        output[i] = input[i] * extra_params.in_weight[i];
        // note that zero_layer_jacobian.d_cell is unused
        *zero_layer_jacobian.d_hidden[i].d_extra_in_weight = input[i];
        for (int j = 0; j < l; ++j)
        {
            zero_layer_jacobian.d_hidden[i].d_weight_forget[j] = 0.;
            zero_layer_jacobian.d_hidden[i].d_weight_ingate[j] = 0.;
            zero_layer_jacobian.d_hidden[i].d_weight_outgate[j] = 0.;
            zero_layer_jacobian.d_hidden[i].d_weight_change[j] = 0.;
            zero_layer_jacobian.d_hidden[i].d_bias_forget[j] = 0.;
            zero_layer_jacobian.d_hidden[i].d_bias_ingate[j] = 0.;
            zero_layer_jacobian.d_hidden[i].d_bias_outgate[j] = 0.;
            zero_layer_jacobian.d_hidden[i].d_bias_change[j] = 0.;
            zero_layer_jacobian.d_hidden[i].d_hidden[j] = 0.;
            zero_layer_jacobian.d_hidden[i].d_cell[j] = 0.;
        }
        //output_jacobian.d_prediction[i].d_extra_in_weight = input[i];
        //x2_d_w2[3 * i] = x[i];
    }

    // Pointer to current x value
    T* layer_output = output;
    LayerStateJacobianPredict<T>* prev_layer_jacobian = &zero_layer_jacobian;
    //T* xp = x2;

    // Derivative vectors for use in lstm_model_d
    ModelJacobian<T> layer_state_d(b);
    //	named based on their relation to variables in lstm_predict_d
    //vector<T> si_d_all(8 * b * b + 3 * b),
    //    si1_d_all(8 * b * b + 3 * b);
    // si_d_all is the result at &s[i] wrt all relevant variables
    // si1_d_all is the result at &s[i + b] wrt all relevant variables

    // Pointers to relevant points in these vectors
    //	(only 2 vectors passed for efficiency, but they
    //	represent lots of different data)
    //T* si_d_wi = &si_d_all[0];
    //T* si_d_wi1 = &si_d_all[4 * b * b];
    //T* si_d_si = &si_d_all[8 * b * b];
    //T* si_d_si1 = &si_d_all[8 * b * b + b];
    //T* si_d_x = &si_d_all[8 * b * b + 2 * b];
    //T* si1_d_wi = &si1_d_all[0];
    //T* si1_d_wi1 = &si1_d_all[4 * b * b];
    //T* si1_d_si = &si1_d_all[8 * b * b];
    //T* si1_d_si1 = &si1_d_all[8 * b * b + b];
    //T* si1_d_x = &si1_d_all[8 * b * b + 2 * b];

    // Main LSTM loop (from predict())
    for (int i = 0; i < l; ++i)
    {
        lstm_model_d(b, main_params.layer_params[i], state.layer_state[i], layer_output, layer_state_d);
        layer_output = state.layer_state[i].hidden;

        // set state_jacobian.layer[i],
        for (int j = 0; j < b; ++j)
        {
            T hidden_j_d_input = layer_state_d.hidden[j].d_input;
            T cell_j_d_input = layer_state_d.cell[j].d_input;
            *state_jacobian.layer[i].d_hidden[j].d_extra_in_weight = hidden_j_d_input * (*prev_layer_jacobian->d_hidden[j].d_extra_in_weight);
            *state_jacobian.layer[i].d_cell[j].d_extra_in_weight = cell_j_d_input * (*prev_layer_jacobian->d_hidden[j].d_extra_in_weight);
            for (int k = 0; k < i ; ++k)
            {
                state_jacobian.layer[i].d_hidden[j].d_weight_forget[k] = hidden_j_d_input * prev_layer_jacobian->d_hidden[j].d_weight_forget[k];
                state_jacobian.layer[i].d_hidden[j].d_weight_ingate[k] = hidden_j_d_input * prev_layer_jacobian->d_hidden[j].d_weight_ingate[k];
                state_jacobian.layer[i].d_hidden[j].d_weight_outgate[k] = hidden_j_d_input * prev_layer_jacobian->d_hidden[j].d_weight_outgate[k];
                state_jacobian.layer[i].d_hidden[j].d_weight_change[k] = hidden_j_d_input * prev_layer_jacobian->d_hidden[j].d_weight_change[k];
                state_jacobian.layer[i].d_hidden[j].d_bias_forget[k] = hidden_j_d_input * prev_layer_jacobian->d_hidden[j].d_bias_forget[k];
                state_jacobian.layer[i].d_hidden[j].d_bias_ingate[k] = hidden_j_d_input * prev_layer_jacobian->d_hidden[j].d_bias_ingate[k];
                state_jacobian.layer[i].d_hidden[j].d_bias_outgate[k] = hidden_j_d_input * prev_layer_jacobian->d_hidden[j].d_bias_outgate[k];
                state_jacobian.layer[i].d_hidden[j].d_bias_change[k] = hidden_j_d_input * prev_layer_jacobian->d_hidden[j].d_bias_change[k];
                state_jacobian.layer[i].d_hidden[j].d_hidden[k] = hidden_j_d_input * prev_layer_jacobian->d_hidden[j].d_hidden[k];
                state_jacobian.layer[i].d_hidden[j].d_cell[k] = hidden_j_d_input * prev_layer_jacobian->d_hidden[j].d_cell[k];
                state_jacobian.layer[i].d_cell[j].d_weight_forget[k] = cell_j_d_input * prev_layer_jacobian->d_hidden[j].d_weight_forget[k];
                state_jacobian.layer[i].d_cell[j].d_weight_ingate[k] = cell_j_d_input * prev_layer_jacobian->d_hidden[j].d_weight_ingate[k];
                state_jacobian.layer[i].d_cell[j].d_weight_outgate[k] = cell_j_d_input * prev_layer_jacobian->d_hidden[j].d_weight_outgate[k];
                state_jacobian.layer[i].d_cell[j].d_weight_change[k] = cell_j_d_input * prev_layer_jacobian->d_hidden[j].d_weight_change[k];
                state_jacobian.layer[i].d_cell[j].d_bias_forget[k] = cell_j_d_input * prev_layer_jacobian->d_hidden[j].d_bias_forget[k];
                state_jacobian.layer[i].d_cell[j].d_bias_ingate[k] = cell_j_d_input * prev_layer_jacobian->d_hidden[j].d_bias_ingate[k];
                state_jacobian.layer[i].d_cell[j].d_bias_outgate[k] = cell_j_d_input * prev_layer_jacobian->d_hidden[j].d_bias_outgate[k];
                state_jacobian.layer[i].d_cell[j].d_bias_change[k] = cell_j_d_input * prev_layer_jacobian->d_hidden[j].d_bias_change[k];
                state_jacobian.layer[i].d_cell[j].d_hidden[k] = cell_j_d_input * prev_layer_jacobian->d_hidden[j].d_hidden[k];
                state_jacobian.layer[i].d_cell[j].d_cell[k] = cell_j_d_input * prev_layer_jacobian->d_hidden[j].d_cell[k];
            }
            state_jacobian.layer[i].d_hidden[j].d_weight_forget[i] = layer_state_d.hidden[j].d_weight.forget;
            state_jacobian.layer[i].d_hidden[j].d_weight_ingate[i] = layer_state_d.hidden[j].d_weight.ingate;
            state_jacobian.layer[i].d_hidden[j].d_weight_outgate[i] = layer_state_d.hidden[j].d_weight.outgate;
            state_jacobian.layer[i].d_hidden[j].d_weight_change[i] = layer_state_d.hidden[j].d_weight.change;
            state_jacobian.layer[i].d_hidden[j].d_bias_forget[i] = layer_state_d.hidden[j].d_bias.forget;
            state_jacobian.layer[i].d_hidden[j].d_bias_ingate[i] = layer_state_d.hidden[j].d_bias.ingate;
            state_jacobian.layer[i].d_hidden[j].d_bias_outgate[i] = layer_state_d.hidden[j].d_bias.outgate;
            state_jacobian.layer[i].d_hidden[j].d_bias_change[i] = layer_state_d.hidden[j].d_bias.change;
            state_jacobian.layer[i].d_hidden[j].d_hidden[i] = layer_state_d.hidden[j].d_hidden;
            state_jacobian.layer[i].d_hidden[j].d_cell[i] = layer_state_d.hidden[j].d_cell;
            for (int k = i + 1; k < l; ++k)
            {
                state_jacobian.layer[i].d_hidden[j].d_weight_forget[k] = 0.;
                state_jacobian.layer[i].d_hidden[j].d_weight_ingate[k] = 0.;
                state_jacobian.layer[i].d_hidden[j].d_weight_outgate[k] = 0.;
                state_jacobian.layer[i].d_hidden[j].d_weight_change[k] = 0.;
                state_jacobian.layer[i].d_hidden[j].d_bias_forget[k] = 0.;
                state_jacobian.layer[i].d_hidden[j].d_bias_ingate[k] = 0.;
                state_jacobian.layer[i].d_hidden[j].d_bias_outgate[k] = 0.;
                state_jacobian.layer[i].d_hidden[j].d_bias_change[k] = 0.;
                state_jacobian.layer[i].d_hidden[j].d_hidden[k] = 0.;
                state_jacobian.layer[i].d_hidden[j].d_cell[k] = 0.;
                state_jacobian.layer[i].d_cell[j].d_weight_forget[k] = 0.;
                state_jacobian.layer[i].d_cell[j].d_weight_ingate[k] = 0.;
                state_jacobian.layer[i].d_cell[j].d_weight_outgate[k] = 0.;
                state_jacobian.layer[i].d_cell[j].d_weight_change[k] = 0.;
                state_jacobian.layer[i].d_cell[j].d_bias_forget[k] = 0.;
                state_jacobian.layer[i].d_cell[j].d_bias_ingate[k] = 0.;
                state_jacobian.layer[i].d_cell[j].d_bias_outgate[k] = 0.;
                state_jacobian.layer[i].d_cell[j].d_bias_change[k] = 0.;
                state_jacobian.layer[i].d_cell[j].d_hidden[k] = 0.;
                state_jacobian.layer[i].d_cell[j].d_cell[k] = 0.;
            }
        }
        prev_layer_jacobian = &state_jacobian.layer[i];
    }
    //for (int i = 0; i < 2 * l * b; i += 2 * b) {
    //    lstm_model_d(b, &w[i * 4], &w[(i + b) * 4], &s[i], &s[i + b], xp,
    //        si_d_all.data(), si1_d_all.data());
    //    xp = &s[i];

    //    // NOTE the following loop basically doesn't work
    //    //	but it may contain useful elements
    //    for (int j = 0; j < b; j++) {
    //        for (int k = 0; k < 4 * b; k++) {
    //            // TODO multiply the x2[prev]_d_w[:current]
    //            //	*= by x2[current]_d_x2[prev]
    //            // x2[prev]_d_w[:current] -> shape (b, i - 1, 4 * b)
    //            // x2[current]_d_x2[prev] -> shape (b, b)

    //            // Update the derivatives of x wrt all previous w[i] vals
    //            //	by multiplying by current_d_x
    //            //  where m is a layer
    //            for (int m = 0; m < i; m++) {
    //                x2_d_w[j * 2 * l * 4 * b + m * 4 + k] *= si_d_x[j];
    //                x2_d_w[j * 2 * l * 4 * b + (m + 1) * 4 + k] *= si_d_x[j];
    //            }

    //            // Set the derivative of x wrt current w[i] val
    //            x2_d_w[j * 2 * l * 4 * b + i * 4 + k] = si_d_wi[j * 4 * b + k];
    //            x2_d_w[j * 2 * l * 4 * b + (i + 1) * 4 + k] = si_d_wi1[j * 4 * b + k];
    //            // index is [j, i, k]
    //        }
    //    }

        //std::cout << "loop" << std::endl;
    //}

    // Final changes (from predict())
    for (int i = 0; i < b; ++i)
    {
        T cur_out_weight = extra_params.out_weight[i];
        output[i] = layer_output[i] * cur_out_weight + extra_params.out_bias[i];
        *output_jacobian.d_prediction[i].d_extra_in_weight = cur_out_weight * (*prev_layer_jacobian->d_hidden[i].d_extra_in_weight);
        *output_jacobian.d_prediction[i].d_extra_out_weight = layer_output[i];
        *output_jacobian.d_prediction[i].d_extra_out_bias = 1.;
        for (int j = 0; j < l; ++j)
        {
            output_jacobian.d_prediction[i].d_weight_forget[j] = cur_out_weight * prev_layer_jacobian->d_hidden[i].d_weight_forget[j];
            output_jacobian.d_prediction[i].d_weight_ingate[j] = cur_out_weight * prev_layer_jacobian->d_hidden[i].d_weight_ingate[j];
            output_jacobian.d_prediction[i].d_weight_outgate[j] = cur_out_weight * prev_layer_jacobian->d_hidden[i].d_weight_outgate[j];
            output_jacobian.d_prediction[i].d_weight_change[j] = cur_out_weight * prev_layer_jacobian->d_hidden[i].d_weight_change[j];
            output_jacobian.d_prediction[i].d_bias_forget[j] = cur_out_weight * prev_layer_jacobian->d_hidden[i].d_bias_forget[j];
            output_jacobian.d_prediction[i].d_bias_ingate[j] = cur_out_weight * prev_layer_jacobian->d_hidden[i].d_bias_ingate[j];
            output_jacobian.d_prediction[i].d_bias_outgate[j] = cur_out_weight * prev_layer_jacobian->d_hidden[i].d_bias_outgate[j];
            output_jacobian.d_prediction[i].d_bias_change[j] = cur_out_weight * prev_layer_jacobian->d_hidden[i].d_bias_change[j];
            output_jacobian.d_prediction[i].d_hidden[j] = cur_out_weight * prev_layer_jacobian->d_hidden[i].d_hidden[j];
            output_jacobian.d_prediction[i].d_cell[j] = cur_out_weight * prev_layer_jacobian->d_hidden[i].d_cell[j];
        }
    }
    //for (int i = 0; i < b; i++) {
    //    x2[i] = xp[i] * w2[b + i] + w2[2 * b + i];

    //    // NOTE these should be correct
    //    x2_d_w2[3 * i + 1] = xp[i];
    //    x2_d_w2[3 * i + 2] = 1;
    //}
    // x2 is the prediction
    // s (state) is also updated
}

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

    GradByParams(T* grad_raw, int hsize, int n_layers) :
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
};


// Derivative of main lstm_objective
//	loss (output)
//	w.r.t. main_params and extra_params (inputs)
//	NOTE this is not done
//	will need to be done after lstm_predict_d
void lstm_objective_d(int l, int c, int b,
    const double* main_params, const double* extra_params,
    std::vector<double> state, const double* sequence,
    double* loss, double* J)
{
    double total = 0.0;
    int count = 0;
    int main_params_count = 8 * l * b;
    int extra_params_count = 3 * b;
    int total_params_count = main_params_count + extra_params_count;
    MainParams<double> main_params_wrap(main_params, b, l);
    ExtraParams<double> extra_params_wrap(extra_params, b);
    State<double> state_wrap(state.data(), b, l);
    InputSequence<double> sequence_wrap(sequence, b, c);
    vector<double> ypred(b), ynorm(b), lse_d(b);
    vector<double> grad_lse_ypred_raw(total_params_count);
    vector<double> prev_state_jacobian_raw(((10 * l + 1) * b) * l), state_jacobian_raw(((10 * l + 1) * b) * l), ypred_jacobian_raw((10 * l + 3) * b);
    StateJacobianPredict<double> prev_state_jacobian(prev_state_jacobian_raw.data(), l, b), state_jacobian(state_jacobian_raw.data(), l, b);
    PredictionJacobian<double> ypred_jacobian(ypred_jacobian_raw.data(), l, b);

    std::fill_n(J, total_params_count, 0.);
    GradByParams<double> j_wrap(J, b, l), grad_lse_ypred(grad_lse_ypred_raw.data(), b, l);

    std::vector<std::vector<double>> j_ypred_raw;
    j_ypred_raw.reserve(b);
    for (int i = -0; i < b; ++i)
        j_ypred_raw.emplace_back(total_params_count);

    std::vector<GradByParams<double>> j_ypred;

    lstm_predict_d(l, b, main_params_wrap, extra_params_wrap, state_wrap, sequence_wrap.sequence[0], ypred.data(), prev_state_jacobian, ypred_jacobian);

    double lse = logsumexp_d(ypred.data(), b, lse_d.data());
    for (int i = 0; i < b; ++i)
    {
        double lse_d_i = lse_d[i];
        for (int j = 0; j < l; ++j)
        {
            grad_lse_ypred.layer[j].d_weight.forget[i] = lse_d_i * ypred_jacobian.d_prediction[i].d_weight_forget[j];
            grad_lse_ypred.layer[j].d_weight.ingate[i] = lse_d_i * ypred_jacobian.d_prediction[i].d_weight_ingate[j];
            grad_lse_ypred.layer[j].d_weight.outgate[i] = lse_d_i * ypred_jacobian.d_prediction[i].d_weight_outgate[j];
            grad_lse_ypred.layer[j].d_weight.change[i] = lse_d_i * ypred_jacobian.d_prediction[i].d_weight_change[j];
            grad_lse_ypred.layer[j].d_bias.forget[i] = lse_d_i * ypred_jacobian.d_prediction[i].d_bias_forget[j];
            grad_lse_ypred.layer[j].d_bias.ingate[i] = lse_d_i * ypred_jacobian.d_prediction[i].d_bias_ingate[j];
            grad_lse_ypred.layer[j].d_bias.outgate[i] = lse_d_i * ypred_jacobian.d_prediction[i].d_bias_outgate[j];
            grad_lse_ypred.layer[j].d_bias.change[i] = lse_d_i * ypred_jacobian.d_prediction[i].d_bias_change[j];
        }
        grad_lse_ypred.d_in_weight[i] = lse_d_i * (*ypred_jacobian.d_prediction[i].d_extra_in_weight);
        grad_lse_ypred.d_out_weight[i] = lse_d_i * (*ypred_jacobian.d_prediction[i].d_extra_out_weight);
        grad_lse_ypred.d_out_bias[i] = lse_d_i * (*ypred_jacobian.d_prediction[i].d_extra_out_bias);
    }

    for (int i = 0; i < b; ++i)
        ynorm[i] = ypred[i] - lse;

    const double* ygold = sequence_wrap.sequence[1];
    for (int i = 0; i < b; ++i)
    {
        double ygold_i = ygold[i];
        total += ygold_i * ynorm[i];

        for (int j = 0; j < b; ++j)
        {
            if (i != j)
            {
                for (int k = 0; k < l; ++k)
                {
                    j_wrap.layer[k].d_weight.forget[j] -= ygold_i * grad_lse_ypred.layer[k].d_weight.forget[i];
                    j_wrap.layer[k].d_weight.ingate[j] -= ygold_i * grad_lse_ypred.layer[k].d_weight.ingate[i];
                    j_wrap.layer[k].d_weight.outgate[j] -= ygold_i * grad_lse_ypred.layer[k].d_weight.outgate[i];
                    j_wrap.layer[k].d_weight.change[j] -= ygold_i * grad_lse_ypred.layer[k].d_weight.change[i];
                    j_wrap.layer[k].d_bias.forget[j] -= ygold_i * grad_lse_ypred.layer[k].d_bias.forget[i];
                    j_wrap.layer[k].d_bias.ingate[j] -= ygold_i * grad_lse_ypred.layer[k].d_bias.ingate[i];
                    j_wrap.layer[k].d_bias.outgate[j] -= ygold_i * grad_lse_ypred.layer[k].d_bias.outgate[i];
                    j_wrap.layer[k].d_bias.change[j] -= ygold_i * grad_lse_ypred.layer[k].d_bias.change[i];
                }
                j_wrap.d_in_weight[j] -= ygold_i * grad_lse_ypred.d_in_weight[i];
                j_wrap.d_out_weight[j] -= ygold_i * grad_lse_ypred.d_out_weight[i];
                j_wrap.d_out_bias[j] -= ygold_i * grad_lse_ypred.d_out_bias[i];
            }
            else
            {
                for (int k = 0; k < l; ++k)
                {
                    j_wrap.layer[k].d_weight.forget[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_weight_forget[k] - grad_lse_ypred.layer[k].d_weight.forget[i]);
                    j_wrap.layer[k].d_weight.ingate[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_weight_ingate[k] - grad_lse_ypred.layer[k].d_weight.ingate[i]);
                    j_wrap.layer[k].d_weight.outgate[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_weight_outgate[k] - grad_lse_ypred.layer[k].d_weight.outgate[i]);
                    j_wrap.layer[k].d_weight.change[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_weight_change[k] - grad_lse_ypred.layer[k].d_weight.change[i]);
                    j_wrap.layer[k].d_bias.forget[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_bias_forget[k] - grad_lse_ypred.layer[k].d_bias.forget[i]);
                    j_wrap.layer[k].d_bias.ingate[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_bias_ingate[k] - grad_lse_ypred.layer[k].d_bias.ingate[i]);
                    j_wrap.layer[k].d_bias.outgate[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_bias_outgate[k] - grad_lse_ypred.layer[k].d_bias.outgate[i]);
                    j_wrap.layer[k].d_bias.change[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_bias_change[k] - ygold_i * grad_lse_ypred.layer[k].d_bias.change[i]);
                }
                j_wrap.d_in_weight[j] += ygold_i * ((*ypred_jacobian.d_prediction[i].d_extra_in_weight) - grad_lse_ypred.d_in_weight[i]);
                j_wrap.d_out_weight[j] += ygold_i * ((*ypred_jacobian.d_prediction[i].d_extra_out_weight) - grad_lse_ypred.d_out_weight[i]);
                j_wrap.d_out_bias[j] += ygold_i * ((*ypred_jacobian.d_prediction[i].d_extra_out_bias) - grad_lse_ypred.d_out_bias[i]);
            }
        }
    }

    count += b;
    for (int t = 1; t < c - 1; ++t)
    {
        lstm_predict_d(l, b, main_params_wrap, extra_params_wrap, state_wrap, sequence_wrap.sequence[t], ypred.data(), state_jacobian, ypred_jacobian);

        // Adding (D state_t / D state_(t-1)) * (D state_(t-1) / D params) to state_jacobian w.r.t. params
        for (int pos = 0; pos < b; ++pos)
        {
            for (int i = 0; i < l; ++i)
            {
                for (int j = 0; j < l; ++j)
                {
                    for (int k = 0; k < l; ++k)
                    {
                        state_jacobian.layer[i].d_hidden[pos].d_weight_forget[k] +=
                            state_jacobian.layer[i].d_hidden[pos].d_hidden[j] * prev_state_jacobian.layer[j].d_hidden[pos].d_weight_forget[k]
                            + state_jacobian.layer[i].d_hidden[pos].d_cell[j] * prev_state_jacobian.layer[j].d_cell[pos].d_weight_forget[k];
                        state_jacobian.layer[i].d_cell[pos].d_weight_forget[k] +=
                            state_jacobian.layer[i].d_cell[pos].d_hidden[j] * prev_state_jacobian.layer[j].d_hidden[pos].d_weight_forget[k]
                            + state_jacobian.layer[i].d_cell[pos].d_cell[j] * prev_state_jacobian.layer[j].d_cell[pos].d_weight_forget[k];
                        state_jacobian.layer[i].d_hidden[pos].d_weight_ingate[k] +=
                            state_jacobian.layer[i].d_hidden[pos].d_hidden[j] * prev_state_jacobian.layer[j].d_hidden[pos].d_weight_ingate[k]
                            + state_jacobian.layer[i].d_hidden[pos].d_cell[j] * prev_state_jacobian.layer[j].d_cell[pos].d_weight_ingate[k];
                        state_jacobian.layer[i].d_cell[pos].d_weight_ingate[k] +=
                            state_jacobian.layer[i].d_cell[pos].d_hidden[j] * prev_state_jacobian.layer[j].d_hidden[pos].d_weight_ingate[k]
                            + state_jacobian.layer[i].d_cell[pos].d_cell[j] * prev_state_jacobian.layer[j].d_cell[pos].d_weight_ingate[k];
                        state_jacobian.layer[i].d_hidden[pos].d_weight_outgate[k] +=
                            state_jacobian.layer[i].d_hidden[pos].d_hidden[j] * prev_state_jacobian.layer[j].d_hidden[pos].d_weight_outgate[k]
                            + state_jacobian.layer[i].d_hidden[pos].d_cell[j] * prev_state_jacobian.layer[j].d_cell[pos].d_weight_outgate[k];
                        state_jacobian.layer[i].d_cell[pos].d_weight_outgate[k] +=
                            state_jacobian.layer[i].d_cell[pos].d_hidden[j] * prev_state_jacobian.layer[j].d_hidden[pos].d_weight_outgate[k]
                            + state_jacobian.layer[i].d_cell[pos].d_cell[j] * prev_state_jacobian.layer[j].d_cell[pos].d_weight_outgate[k];
                        state_jacobian.layer[i].d_hidden[pos].d_weight_change[k] +=
                            state_jacobian.layer[i].d_hidden[pos].d_hidden[j] * prev_state_jacobian.layer[j].d_hidden[pos].d_weight_change[k]
                            + state_jacobian.layer[i].d_hidden[pos].d_cell[j] * prev_state_jacobian.layer[j].d_cell[pos].d_weight_change[k];
                        state_jacobian.layer[i].d_cell[pos].d_weight_change[k] +=
                            state_jacobian.layer[i].d_cell[pos].d_hidden[j] * prev_state_jacobian.layer[j].d_hidden[pos].d_weight_change[k]
                            + state_jacobian.layer[i].d_cell[pos].d_cell[j] * prev_state_jacobian.layer[j].d_cell[pos].d_weight_change[k];

                        state_jacobian.layer[i].d_hidden[pos].d_bias_forget[k] +=
                            state_jacobian.layer[i].d_hidden[pos].d_hidden[j] * prev_state_jacobian.layer[j].d_hidden[pos].d_bias_forget[k]
                            + state_jacobian.layer[i].d_hidden[pos].d_cell[j] * prev_state_jacobian.layer[j].d_cell[pos].d_bias_forget[k];
                        state_jacobian.layer[i].d_cell[pos].d_bias_forget[k] +=
                            state_jacobian.layer[i].d_cell[pos].d_hidden[j] * prev_state_jacobian.layer[j].d_hidden[pos].d_bias_forget[k]
                            + state_jacobian.layer[i].d_cell[pos].d_cell[j] * prev_state_jacobian.layer[j].d_cell[pos].d_bias_forget[k];
                        state_jacobian.layer[i].d_hidden[pos].d_bias_ingate[k] +=
                            state_jacobian.layer[i].d_hidden[pos].d_hidden[j] * prev_state_jacobian.layer[j].d_hidden[pos].d_bias_ingate[k]
                            + state_jacobian.layer[i].d_hidden[pos].d_cell[j] * prev_state_jacobian.layer[j].d_cell[pos].d_bias_ingate[k];
                        state_jacobian.layer[i].d_cell[pos].d_bias_ingate[k] +=
                            state_jacobian.layer[i].d_cell[pos].d_hidden[j] * prev_state_jacobian.layer[j].d_hidden[pos].d_bias_ingate[k]
                            + state_jacobian.layer[i].d_cell[pos].d_cell[j] * prev_state_jacobian.layer[j].d_cell[pos].d_bias_ingate[k];
                        state_jacobian.layer[i].d_hidden[pos].d_bias_outgate[k] +=
                            state_jacobian.layer[i].d_hidden[pos].d_hidden[j] * prev_state_jacobian.layer[j].d_hidden[pos].d_bias_outgate[k]
                            + state_jacobian.layer[i].d_hidden[pos].d_cell[j] * prev_state_jacobian.layer[j].d_cell[pos].d_bias_outgate[k];
                        state_jacobian.layer[i].d_cell[pos].d_bias_outgate[k] +=
                            state_jacobian.layer[i].d_cell[pos].d_hidden[j] * prev_state_jacobian.layer[j].d_hidden[pos].d_bias_outgate[k]
                            + state_jacobian.layer[i].d_cell[pos].d_cell[j] * prev_state_jacobian.layer[j].d_cell[pos].d_bias_outgate[k];
                        state_jacobian.layer[i].d_hidden[pos].d_bias_change[k] +=
                            state_jacobian.layer[i].d_hidden[pos].d_hidden[j] * prev_state_jacobian.layer[j].d_hidden[pos].d_bias_change[k]
                            + state_jacobian.layer[i].d_hidden[pos].d_cell[j] * prev_state_jacobian.layer[j].d_cell[pos].d_bias_change[k];
                        state_jacobian.layer[i].d_cell[pos].d_bias_change[k] +=
                            state_jacobian.layer[i].d_cell[pos].d_hidden[j] * prev_state_jacobian.layer[j].d_hidden[pos].d_bias_change[k]
                            + state_jacobian.layer[i].d_cell[pos].d_cell[j] * prev_state_jacobian.layer[j].d_cell[pos].d_bias_change[k];
                    }
                    *state_jacobian.layer[i].d_hidden[pos].d_extra_in_weight +=
                        state_jacobian.layer[i].d_hidden[pos].d_hidden[j] * (*prev_state_jacobian.layer[j].d_hidden[pos].d_extra_in_weight)
                        + state_jacobian.layer[i].d_hidden[pos].d_cell[j] * (*prev_state_jacobian.layer[j].d_cell[pos].d_extra_in_weight);
                    *state_jacobian.layer[i].d_cell[pos].d_extra_in_weight +=
                        state_jacobian.layer[i].d_cell[pos].d_hidden[j] * (*prev_state_jacobian.layer[j].d_hidden[pos].d_extra_in_weight)
                        + state_jacobian.layer[i].d_cell[pos].d_cell[j] * (*prev_state_jacobian.layer[j].d_cell[pos].d_extra_in_weight);
                }
            }
        }

        // Adding (D pred / D state_(t-1)) * (D state_(t-1) / D params) to ypred_jacobian w.r.t. params
        for (int pos = 0; pos < b; ++pos)
        {
            for (int i = 0; i < l; ++i)
            {
                for (int j = 0; j < l; ++j)
                {
                    ypred_jacobian.d_prediction[pos].d_weight_forget[j] +=
                        ypred_jacobian.d_prediction[pos].d_hidden[i] * prev_state_jacobian.layer[i].d_hidden[pos].d_weight_forget[j]
                        + ypred_jacobian.d_prediction[pos].d_cell[i] * prev_state_jacobian.layer[i].d_cell[pos].d_weight_forget[j];
                    ypred_jacobian.d_prediction[pos].d_weight_ingate[j] +=
                        ypred_jacobian.d_prediction[pos].d_hidden[i] * prev_state_jacobian.layer[i].d_hidden[pos].d_weight_ingate[j]
                        + ypred_jacobian.d_prediction[pos].d_cell[i] * prev_state_jacobian.layer[i].d_cell[pos].d_weight_ingate[j];
                    ypred_jacobian.d_prediction[pos].d_weight_outgate[j] +=
                        ypred_jacobian.d_prediction[pos].d_hidden[i] * prev_state_jacobian.layer[i].d_hidden[pos].d_weight_outgate[j]
                        + ypred_jacobian.d_prediction[pos].d_cell[i] * prev_state_jacobian.layer[i].d_cell[pos].d_weight_outgate[j];
                    ypred_jacobian.d_prediction[pos].d_weight_change[j] +=
                        ypred_jacobian.d_prediction[pos].d_hidden[i] * prev_state_jacobian.layer[i].d_hidden[pos].d_weight_change[j]
                        + ypred_jacobian.d_prediction[pos].d_cell[i] * prev_state_jacobian.layer[i].d_cell[pos].d_weight_change[j];

                    ypred_jacobian.d_prediction[pos].d_bias_forget[j] +=
                        ypred_jacobian.d_prediction[pos].d_hidden[i] * prev_state_jacobian.layer[i].d_hidden[pos].d_bias_forget[j]
                        + ypred_jacobian.d_prediction[pos].d_cell[i] * prev_state_jacobian.layer[i].d_cell[pos].d_bias_forget[j];
                    ypred_jacobian.d_prediction[pos].d_bias_ingate[j] +=
                        ypred_jacobian.d_prediction[pos].d_hidden[i] * prev_state_jacobian.layer[i].d_hidden[pos].d_bias_ingate[j]
                        + ypred_jacobian.d_prediction[pos].d_cell[i] * prev_state_jacobian.layer[i].d_cell[pos].d_bias_ingate[j];
                    ypred_jacobian.d_prediction[pos].d_bias_outgate[j] +=
                        ypred_jacobian.d_prediction[pos].d_hidden[i] * prev_state_jacobian.layer[i].d_hidden[pos].d_bias_outgate[j]
                        + ypred_jacobian.d_prediction[pos].d_cell[i] * prev_state_jacobian.layer[i].d_cell[pos].d_bias_outgate[j];
                    ypred_jacobian.d_prediction[pos].d_bias_change[j] +=
                        ypred_jacobian.d_prediction[pos].d_hidden[i] * prev_state_jacobian.layer[i].d_hidden[pos].d_bias_change[j]
                        + ypred_jacobian.d_prediction[pos].d_cell[i] * prev_state_jacobian.layer[i].d_cell[pos].d_bias_change[j];
                }
                *ypred_jacobian.d_prediction[pos].d_extra_in_weight +=
                    ypred_jacobian.d_prediction[pos].d_hidden[i] * (*prev_state_jacobian.layer[i].d_hidden[pos].d_extra_in_weight)
                    + ypred_jacobian.d_prediction[pos].d_cell[i] * (*prev_state_jacobian.layer[i].d_cell[pos].d_extra_in_weight);
            }
        }

        double lse = logsumexp_d(ypred.data(), b, lse_d.data());
        // D logsumexp(pred) / D params
        for (int i = 0; i < b; ++i)
        {
            double lse_d_i = lse_d[i];
            for (int j = 0; j < l; ++j)
            {
                grad_lse_ypred.layer[j].d_weight.forget[i] = lse_d_i * ypred_jacobian.d_prediction[i].d_weight_forget[j];
                grad_lse_ypred.layer[j].d_weight.ingate[i] = lse_d_i * ypred_jacobian.d_prediction[i].d_weight_ingate[j];
                grad_lse_ypred.layer[j].d_weight.outgate[i] = lse_d_i * ypred_jacobian.d_prediction[i].d_weight_outgate[j];
                grad_lse_ypred.layer[j].d_weight.change[i] = lse_d_i * ypred_jacobian.d_prediction[i].d_weight_change[j];
                grad_lse_ypred.layer[j].d_bias.forget[i] = lse_d_i * ypred_jacobian.d_prediction[i].d_bias_forget[j];
                grad_lse_ypred.layer[j].d_bias.ingate[i] = lse_d_i * ypred_jacobian.d_prediction[i].d_bias_ingate[j];
                grad_lse_ypred.layer[j].d_bias.outgate[i] = lse_d_i * ypred_jacobian.d_prediction[i].d_bias_outgate[j];
                grad_lse_ypred.layer[j].d_bias.change[i] = lse_d_i * ypred_jacobian.d_prediction[i].d_bias_change[j];
            }
            grad_lse_ypred.d_in_weight[i] = lse_d_i * (*ypred_jacobian.d_prediction[i].d_extra_in_weight);
            grad_lse_ypred.d_out_weight[i] = lse_d_i * (*ypred_jacobian.d_prediction[i].d_extra_out_weight);
            grad_lse_ypred.d_out_bias[i] = lse_d_i * (*ypred_jacobian.d_prediction[i].d_extra_out_bias);
        }

        for (int i = 0; i < b; ++i)
            ynorm[i] = ypred[i] - lse;

        const double* ygold = sequence_wrap.sequence[t + 1];

        for (int i = 0; i < b; ++i)
        {
            double ygold_i = ygold[i];
            total += ygold_i * ynorm[i];

            for (int j = 0; j < b; ++j)
            {
                if (i != j)
                {
                    for (int k = 0; k < l; ++k)
                    {
                        j_wrap.layer[k].d_weight.forget[j] -= ygold_i * grad_lse_ypred.layer[k].d_weight.forget[i];
                        j_wrap.layer[k].d_weight.ingate[j] -= ygold_i * grad_lse_ypred.layer[k].d_weight.ingate[i];
                        j_wrap.layer[k].d_weight.outgate[j] -= ygold_i * grad_lse_ypred.layer[k].d_weight.outgate[i];
                        j_wrap.layer[k].d_weight.change[j] -= ygold_i * grad_lse_ypred.layer[k].d_weight.change[i];
                        j_wrap.layer[k].d_bias.forget[j] -= ygold_i * grad_lse_ypred.layer[k].d_bias.forget[i];
                        j_wrap.layer[k].d_bias.ingate[j] -= ygold_i * grad_lse_ypred.layer[k].d_bias.ingate[i];
                        j_wrap.layer[k].d_bias.outgate[j] -= ygold_i * grad_lse_ypred.layer[k].d_bias.outgate[i];
                        j_wrap.layer[k].d_bias.change[j] -= ygold_i * grad_lse_ypred.layer[k].d_bias.change[i];
                    }
                    j_wrap.d_in_weight[j] -= ygold_i * grad_lse_ypred.d_in_weight[i];
                    j_wrap.d_out_weight[j] -= ygold_i * grad_lse_ypred.d_out_weight[i];
                    j_wrap.d_out_bias[j] -= ygold_i * grad_lse_ypred.d_out_bias[i];
                }
                else
                {
                    for (int k = 0; k < l; ++k)
                    {
                        j_wrap.layer[k].d_weight.forget[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_weight_forget[k] - grad_lse_ypred.layer[k].d_weight.forget[i]);
                        j_wrap.layer[k].d_weight.ingate[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_weight_ingate[k] - grad_lse_ypred.layer[k].d_weight.ingate[i]);
                        j_wrap.layer[k].d_weight.outgate[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_weight_outgate[k] - grad_lse_ypred.layer[k].d_weight.outgate[i]);
                        j_wrap.layer[k].d_weight.change[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_weight_change[k] - grad_lse_ypred.layer[k].d_weight.change[i]);
                        j_wrap.layer[k].d_bias.forget[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_bias_forget[k] - grad_lse_ypred.layer[k].d_bias.forget[i]);
                        j_wrap.layer[k].d_bias.ingate[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_bias_ingate[k] - grad_lse_ypred.layer[k].d_bias.ingate[i]);
                        j_wrap.layer[k].d_bias.outgate[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_bias_outgate[k] - grad_lse_ypred.layer[k].d_bias.outgate[i]);
                        j_wrap.layer[k].d_bias.change[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_bias_change[k] - ygold_i * grad_lse_ypred.layer[k].d_bias.change[i]);
                    }
                    j_wrap.d_in_weight[j] += ygold_i * ((*ypred_jacobian.d_prediction[i].d_extra_in_weight) - grad_lse_ypred.d_in_weight[i]);
                    j_wrap.d_out_weight[j] += ygold_i * ((*ypred_jacobian.d_prediction[i].d_extra_out_weight) - grad_lse_ypred.d_out_weight[i]);
                    j_wrap.d_out_bias[j] += ygold_i * ((*ypred_jacobian.d_prediction[i].d_extra_out_bias) - grad_lse_ypred.d_out_bias[i]);
                }
            }
        }

        count += b;
    }

    *loss = -total / count;

    for (int i = 0; i < total_params_count; ++i)
        J[i] /= -(double)count;
}