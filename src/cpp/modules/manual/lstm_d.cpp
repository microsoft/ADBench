#include "lstm_d.h"
#include "lstm_d_structures.h"
#include "../../shared/lstm.h"

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
T logsumexp_d(const T* vect, int sz, T* J) {
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
    }

    // Pointer to current output/next layer's input
    T* layer_output = output;
    // Pointer to the jacobian of the previous layer
    LayerStateJacobianPredict<T>* prev_layer_jacobian = &zero_layer_jacobian;

    ModelJacobian<T> layer_state_d(b);

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
            state_jacobian.layer[i].d_cell[j].d_weight_forget[i] = layer_state_d.cell[j].d_weight.forget;
            state_jacobian.layer[i].d_cell[j].d_weight_ingate[i] = layer_state_d.cell[j].d_weight.ingate;
            state_jacobian.layer[i].d_cell[j].d_weight_outgate[i] = layer_state_d.cell[j].d_weight.outgate;
            state_jacobian.layer[i].d_cell[j].d_weight_change[i] = layer_state_d.cell[j].d_weight.change;
            state_jacobian.layer[i].d_cell[j].d_bias_forget[i] = layer_state_d.cell[j].d_bias.forget;
            state_jacobian.layer[i].d_cell[j].d_bias_ingate[i] = layer_state_d.cell[j].d_bias.ingate;
            state_jacobian.layer[i].d_cell[j].d_bias_outgate[i] = layer_state_d.cell[j].d_bias.outgate;
            state_jacobian.layer[i].d_cell[j].d_bias_change[i] = layer_state_d.cell[j].d_bias.change;
            state_jacobian.layer[i].d_cell[j].d_hidden[i] = layer_state_d.cell[j].d_hidden;
            state_jacobian.layer[i].d_cell[j].d_cell[i] = layer_state_d.cell[j].d_cell;
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
}

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
    vector<double> prev_state_jacobian_raw(((10 * l + 1) * b) * 2 * l), state_jacobian_raw(((10 * l + 1) * b) * 2 * l), ypred_jacobian_raw((10 * l + 3) * b);
    StateJacobianPredict<double> prev_state_jacobian(prev_state_jacobian_raw.data(), l, b), state_jacobian(state_jacobian_raw.data(), l, b);
    PredictionJacobian<double> ypred_jacobian(ypred_jacobian_raw.data(), l, b);

    std::fill_n(J, total_params_count, 0.);
    GradByParams<double> j_wrap(J, b, l), grad_lse_ypred(grad_lse_ypred_raw.data(), b, l);

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
                    j_wrap.layer[k].d_weight.forget[j] -= ygold_i * grad_lse_ypred.layer[k].d_weight.forget[j];
                    j_wrap.layer[k].d_weight.ingate[j] -= ygold_i * grad_lse_ypred.layer[k].d_weight.ingate[j];
                    j_wrap.layer[k].d_weight.outgate[j] -= ygold_i * grad_lse_ypred.layer[k].d_weight.outgate[j];
                    j_wrap.layer[k].d_weight.change[j] -= ygold_i * grad_lse_ypred.layer[k].d_weight.change[j];
                    j_wrap.layer[k].d_bias.ingate[j] -= ygold_i * grad_lse_ypred.layer[k].d_bias.ingate[j];
                    j_wrap.layer[k].d_bias.forget[j] -= ygold_i * grad_lse_ypred.layer[k].d_bias.forget[j];
                    j_wrap.layer[k].d_bias.outgate[j] -= ygold_i * grad_lse_ypred.layer[k].d_bias.outgate[j];
                    j_wrap.layer[k].d_bias.change[j] -= ygold_i * grad_lse_ypred.layer[k].d_bias.change[j];
                }
                j_wrap.d_in_weight[j] -= ygold_i * grad_lse_ypred.d_in_weight[j];
                j_wrap.d_out_weight[j] -= ygold_i * grad_lse_ypred.d_out_weight[j];
                j_wrap.d_out_bias[j] -= ygold_i * grad_lse_ypred.d_out_bias[j];
            }
            else
            {
                for (int k = 0; k < l; ++k)
                {
                    j_wrap.layer[k].d_weight.forget[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_weight_forget[k] - grad_lse_ypred.layer[k].d_weight.forget[j]);
                    j_wrap.layer[k].d_weight.ingate[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_weight_ingate[k] - grad_lse_ypred.layer[k].d_weight.ingate[j]);
                    j_wrap.layer[k].d_weight.outgate[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_weight_outgate[k] - grad_lse_ypred.layer[k].d_weight.outgate[j]);
                    j_wrap.layer[k].d_weight.change[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_weight_change[k] - grad_lse_ypred.layer[k].d_weight.change[j]);
                    j_wrap.layer[k].d_bias.forget[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_bias_forget[k] - grad_lse_ypred.layer[k].d_bias.forget[j]);
                    j_wrap.layer[k].d_bias.ingate[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_bias_ingate[k] - grad_lse_ypred.layer[k].d_bias.ingate[j]);
                    j_wrap.layer[k].d_bias.outgate[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_bias_outgate[k] - grad_lse_ypred.layer[k].d_bias.outgate[j]);
                    j_wrap.layer[k].d_bias.change[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_bias_change[k] - grad_lse_ypred.layer[k].d_bias.change[j]);
                }
                j_wrap.d_in_weight[j] += ygold_i * ((*ypred_jacobian.d_prediction[i].d_extra_in_weight) - grad_lse_ypred.d_in_weight[j]);
                j_wrap.d_out_weight[j] += ygold_i * ((*ypred_jacobian.d_prediction[i].d_extra_out_weight) - grad_lse_ypred.d_out_weight[j]);
                j_wrap.d_out_bias[j] += ygold_i * ((*ypred_jacobian.d_prediction[i].d_extra_out_bias) - grad_lse_ypred.d_out_bias[j]);
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
                        j_wrap.layer[k].d_weight.forget[j] -= ygold_i * grad_lse_ypred.layer[k].d_weight.forget[j];
                        j_wrap.layer[k].d_weight.ingate[j] -= ygold_i * grad_lse_ypred.layer[k].d_weight.ingate[j];
                        j_wrap.layer[k].d_weight.outgate[j] -= ygold_i * grad_lse_ypred.layer[k].d_weight.outgate[j];
                        j_wrap.layer[k].d_weight.change[j] -= ygold_i * grad_lse_ypred.layer[k].d_weight.change[j];
                        j_wrap.layer[k].d_bias.forget[j] -= ygold_i * grad_lse_ypred.layer[k].d_bias.forget[j];
                        j_wrap.layer[k].d_bias.ingate[j] -= ygold_i * grad_lse_ypred.layer[k].d_bias.ingate[j];
                        j_wrap.layer[k].d_bias.outgate[j] -= ygold_i * grad_lse_ypred.layer[k].d_bias.outgate[j];
                        j_wrap.layer[k].d_bias.change[j] -= ygold_i * grad_lse_ypred.layer[k].d_bias.change[j];
                    }
                    j_wrap.d_in_weight[j] -= ygold_i * grad_lse_ypred.d_in_weight[j];
                    j_wrap.d_out_weight[j] -= ygold_i * grad_lse_ypred.d_out_weight[j];
                    j_wrap.d_out_bias[j] -= ygold_i * grad_lse_ypred.d_out_bias[j];
                }
                else
                {
                    for (int k = 0; k < l; ++k)
                    {
                        j_wrap.layer[k].d_weight.forget[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_weight_forget[k] - grad_lse_ypred.layer[k].d_weight.forget[j]);
                        j_wrap.layer[k].d_weight.ingate[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_weight_ingate[k] - grad_lse_ypred.layer[k].d_weight.ingate[j]);
                        j_wrap.layer[k].d_weight.outgate[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_weight_outgate[k] - grad_lse_ypred.layer[k].d_weight.outgate[j]);
                        j_wrap.layer[k].d_weight.change[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_weight_change[k] - grad_lse_ypred.layer[k].d_weight.change[j]);
                        j_wrap.layer[k].d_bias.forget[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_bias_forget[k] - grad_lse_ypred.layer[k].d_bias.forget[j]);
                        j_wrap.layer[k].d_bias.ingate[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_bias_ingate[k] - grad_lse_ypred.layer[k].d_bias.ingate[j]);
                        j_wrap.layer[k].d_bias.outgate[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_bias_outgate[k] - grad_lse_ypred.layer[k].d_bias.outgate[j]);
                        j_wrap.layer[k].d_bias.change[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_bias_change[k] - grad_lse_ypred.layer[k].d_bias.change[j]);
                    }
                    j_wrap.d_in_weight[j] += ygold_i * ((*ypred_jacobian.d_prediction[i].d_extra_in_weight) - grad_lse_ypred.d_in_weight[j]);
                    j_wrap.d_out_weight[j] += ygold_i * ((*ypred_jacobian.d_prediction[i].d_extra_out_weight) - grad_lse_ypred.d_out_weight[j]);
                    j_wrap.d_out_bias[j] += ygold_i * ((*ypred_jacobian.d_prediction[i].d_extra_out_bias) - grad_lse_ypred.d_out_bias[j]);
                }
            }
        }

        count += b;
        swap(state_jacobian, prev_state_jacobian);
    }

    *loss = -total / count;

    for (int i = 0; i < total_params_count; ++i)
        J[i] /= -(double)count;
}