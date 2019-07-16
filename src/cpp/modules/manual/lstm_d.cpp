#include "lstm_d.h"
#include "lstm_d_structures.h"
#include "../../shared/lstm.h"

// UTILS

// Sigmoid diff on scalar
template<typename T>
T sigmoid_d(T x, T* d) {
    T s = sigmoid(x);
    *d = s * (1 - s);
    return s;
}

// tanh diff on scalar
template<typename T>
T tanh_d(T x, T* d) {
    T t = tanh(x);
    *d = 1 - t * t;
    return t;
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

// Manual Jacobian of lstm_model
// Outputs jacobian containing the derivatives of the new state
// with relation to params, state, and input
template<typename T>
void lstm_model_d(int hsize,
    const LayerParams<T>& params,
    LayerState<T>& state,
    const T* input,
    ModelJacobian<T>& jacobian)
{
    for (int i = 0; i < hsize; i++) {
        // Only get relevant derivatives

        T forget_in = input[i] * params.weight.forget[i] + params.bias.forget[i];
        T forget_sd;
        T forget = sigmoid_d(forget_in, &forget_sd);
        T forget_dw = forget_sd * input[i];
        T forget_db = forget_sd;
        T forget_di = forget_sd * params.weight.forget[i];

        T ingate_in = state.hidden[i] * params.weight.ingate[i] + params.bias.ingate[i];
        T ingate_sd;
        T ingate = sigmoid_d(ingate_in, &ingate_sd);
        T ingate_dw = ingate_sd * state.hidden[i];
        T ingate_db = ingate_sd;
        T ingate_dh = ingate_sd * params.weight.ingate[i];

        T outgate_in = input[i] * params.weight.outgate[i] + params.bias.outgate[i];
        T outgate_sd;
        T outgate = sigmoid_d(outgate_in, &outgate_sd);
        T outgate_dw = outgate_sd * input[i];
        T outgate_db = outgate_sd;
        T outgate_di = outgate_sd * params.weight.outgate[i];

        T change_in = state.hidden[i] * params.weight.change[i] + params.bias.change[i];
        T change_td;
        T change = tanh_d(change_in, &change_td);
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
        // wrt bias
        jacobian.cell[i].d_bias.forget = orig_cell * forget_db;
        jacobian.cell[i].d_bias.ingate = change * ingate_db;
        jacobian.cell[i].d_bias.outgate = 0.;
        jacobian.cell[i].d_bias.change = ingate * change_db;
        // wrt hidden, cell(original), input
        jacobian.cell[i].d_hidden = ingate * change_dh + change * ingate_dh;
        jacobian.cell[i].d_cell = forget;
        jacobian.cell[i].d_input = orig_cell * forget_di;

        // Hidden derivatives
        T hidden_td;
        T hidden_t = tanh_d(state.cell[i], &hidden_td);
        state.hidden[i] = outgate * hidden_t;
        hidden_td *= outgate;
        // wrt weight
        jacobian.hidden[i].d_weight.forget = hidden_td * jacobian.cell[i].d_weight.forget;
        jacobian.hidden[i].d_weight.ingate = hidden_td * jacobian.cell[i].d_weight.ingate;
        jacobian.hidden[i].d_weight.outgate = hidden_t * outgate_dw;
        jacobian.hidden[i].d_weight.change = hidden_td * jacobian.cell[i].d_weight.change;
        // wrt bias
        jacobian.hidden[i].d_bias.forget = hidden_td * jacobian.cell[i].d_bias.forget;
        jacobian.hidden[i].d_bias.ingate = hidden_td * jacobian.cell[i].d_bias.ingate;
        jacobian.hidden[i].d_bias.outgate = hidden_t * outgate_db;
        jacobian.hidden[i].d_bias.change = hidden_td * jacobian.cell[i].d_bias.change;
        // wrt hidden, cell (original), input
        jacobian.hidden[i].d_hidden = hidden_td * jacobian.cell[i].d_hidden;
        jacobian.hidden[i].d_cell = hidden_td * jacobian.cell[i].d_cell;
        jacobian.hidden[i].d_input = outgate_di * hidden_t + hidden_td * jacobian.cell[i].d_input;
    }
}


// Manual jacobian of lstm_predict
// Outputs state_jacobian containing the derivatives of the new state
// and output_jacobian containing the derivatives of the output
// with relation to main_params, extra_params, and state
//
// zero_layer_jacobian and layer_state_d are references to
// pre-allocated structures that will be used in computations.
// This function is being called from a long loop, so allocating them only once
// can save some time.
template<typename T>
void lstm_predict_d(int l, int b,
    const MainParams<T>& main_params, const ExtraParams<T>& extra_params,
    State<T>& state,
    const T* input,
    LayerStateJacobianPredict<T>& zero_layer_jacobian,
    ModelJacobian<T>& layer_state_d,
    T* output,
    StateJacobianPredict<T>& state_jacobian,
    PredictionJacobian<T>& output_jacobian)
{
    // Intial setup (from predict())
    for (int i = 0; i < b; ++i) {
        output[i] = input[i] * extra_params.in_weight[i];
        // note that the rest of zero_layer_jacobian.d_hidden and zero_layer_jacobian.d_cell are unused
        *zero_layer_jacobian.d_hidden[i].d_extra_in_weight = input[i];
    }

    // Pointer to current output/next layer's input
    T* layer_output = output;
    // Pointer to the jacobian of the previous layer
    LayerStateJacobianPredict<T>* prev_layer_jacobian = &zero_layer_jacobian;

    // Main LSTM loop (from predict())
    for (int i = 0; i < l; ++i)
    {
        lstm_model_d(b, main_params.layer_params[i], state.layer_state[i], layer_output, layer_state_d);
        layer_output = state.layer_state[i].hidden;

        // set state_jacobian.layer[i]
        for (int j = 0; j < b; ++j)
        {
            T hidden_j_d_input = layer_state_d.hidden[j].d_input;
            T cell_j_d_input = layer_state_d.cell[j].d_input;
            // derivatives by variables on which layer_output depends
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
            // derivatives by variables on which lstm_model_d depends directly
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
            // derivatives by variable on which lstm_model_d does not depend (zero)
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
        // compute output
        output[i] = layer_output[i] * cur_out_weight + extra_params.out_bias[i];
        // compute the derivatives of output
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

// Gradient of the logsumexp(prediction(params)) with relation to params
void logsumexp_grad(int n_layers, int hsize, const std::vector<double>& lse_d, const PredictionJacobian<double>& ypred_jacobian, GradByParams<double>& grad_lse_ypred)
{
    for (int i = 0; i < hsize; ++i)
    {
        double lse_d_i = lse_d[i];
        for (int j = 0; j < n_layers; ++j)
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
}

// Updates the gradient of the loss function (loss_grad) after doing a prediction
// using the gold value for the prediction (ygold),
// jacobian of the prediction with relation to params (ypred_jacobian),
// and the gradient of the logsumexp(prediction(params)) with relation to params (grad_lse_ypred)
void update_loss_gradient(int n_layers, int hsize, const double* ygold, const GradByParams<double>& grad_lse_ypred, const PredictionJacobian<double>& ypred_jacobian, GradByParams<double>& loss_grad)
{
    for (int i = 0; i < hsize; ++i)
    {
        double ygold_i = ygold[i];

        for (int j = 0; j < hsize; ++j)
        {
            if (i != j)
            {
                for (int k = 0; k < n_layers; ++k)
                {
                    loss_grad.layer[k].d_weight.forget[j] -= ygold_i * grad_lse_ypred.layer[k].d_weight.forget[j];
                    loss_grad.layer[k].d_weight.ingate[j] -= ygold_i * grad_lse_ypred.layer[k].d_weight.ingate[j];
                    loss_grad.layer[k].d_weight.outgate[j] -= ygold_i * grad_lse_ypred.layer[k].d_weight.outgate[j];
                    loss_grad.layer[k].d_weight.change[j] -= ygold_i * grad_lse_ypred.layer[k].d_weight.change[j];
                    loss_grad.layer[k].d_bias.ingate[j] -= ygold_i * grad_lse_ypred.layer[k].d_bias.ingate[j];
                    loss_grad.layer[k].d_bias.forget[j] -= ygold_i * grad_lse_ypred.layer[k].d_bias.forget[j];
                    loss_grad.layer[k].d_bias.outgate[j] -= ygold_i * grad_lse_ypred.layer[k].d_bias.outgate[j];
                    loss_grad.layer[k].d_bias.change[j] -= ygold_i * grad_lse_ypred.layer[k].d_bias.change[j];
                }
                loss_grad.d_in_weight[j] -= ygold_i * grad_lse_ypred.d_in_weight[j];
                loss_grad.d_out_weight[j] -= ygold_i * grad_lse_ypred.d_out_weight[j];
                loss_grad.d_out_bias[j] -= ygold_i * grad_lse_ypred.d_out_bias[j];
            }
            else
            {
                for (int k = 0; k < n_layers; ++k)
                {
                    loss_grad.layer[k].d_weight.forget[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_weight_forget[k] - grad_lse_ypred.layer[k].d_weight.forget[j]);
                    loss_grad.layer[k].d_weight.ingate[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_weight_ingate[k] - grad_lse_ypred.layer[k].d_weight.ingate[j]);
                    loss_grad.layer[k].d_weight.outgate[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_weight_outgate[k] - grad_lse_ypred.layer[k].d_weight.outgate[j]);
                    loss_grad.layer[k].d_weight.change[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_weight_change[k] - grad_lse_ypred.layer[k].d_weight.change[j]);
                    loss_grad.layer[k].d_bias.forget[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_bias_forget[k] - grad_lse_ypred.layer[k].d_bias.forget[j]);
                    loss_grad.layer[k].d_bias.ingate[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_bias_ingate[k] - grad_lse_ypred.layer[k].d_bias.ingate[j]);
                    loss_grad.layer[k].d_bias.outgate[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_bias_outgate[k] - grad_lse_ypred.layer[k].d_bias.outgate[j]);
                    loss_grad.layer[k].d_bias.change[j] += ygold_i * (ypred_jacobian.d_prediction[i].d_bias_change[k] - grad_lse_ypred.layer[k].d_bias.change[j]);
                }
                loss_grad.d_in_weight[j] += ygold_i * ((*ypred_jacobian.d_prediction[i].d_extra_in_weight) - grad_lse_ypred.d_in_weight[j]);
                loss_grad.d_out_weight[j] += ygold_i * ((*ypred_jacobian.d_prediction[i].d_extra_out_weight) - grad_lse_ypred.d_out_weight[j]);
                loss_grad.d_out_bias[j] += ygold_i * ((*ypred_jacobian.d_prediction[i].d_extra_out_bias) - grad_lse_ypred.d_out_bias[j]);
            }
        }
    }
}

// Add (D pred / D state_(t-1)) * (D state_(t-1) / D params) to ypred_jacobian with relation to params
void update_pred_jacobian_with_prev_state_jacobian(int n_layers, int hsize, const StateJacobianPredict<double>& prev_state_jacobian, PredictionJacobian<double>& ypred_jacobian)
{
    for (int pos = 0; pos < hsize; ++pos)
    {
        for (int i = 0; i < n_layers; ++i)
        {
            for (int j = 0; j < n_layers; ++j)
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
}

// Add (D state_t / D state_(t-1)) * (D state_(t-1) / D params) to state_jacobian with relation to params
void update_state_jacobian_with_prev_state_jacobian(int n_layers, int hsize, const StateJacobianPredict<double>& prev_state_jacobian, StateJacobianPredict<double>& state_jacobian)
{
    for (int pos = 0; pos < hsize; ++pos)
    {
        for (int i = 0; i < n_layers; ++i)
        {
            for (int j = 0; j < n_layers; ++j)
            {
                for (int k = 0; k < n_layers; ++k)
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
}

// Manual gradient of lstm_objective loss (output)
// with relation to main_params and extra_params (inputs)
void lstm_objective_d(int l, int c, int b,
    const double* main_params, const double* extra_params,
    std::vector<double> state, const double* sequence,
    double* loss, double* J)
{
    double total = 0.0;
    int count = b * (c - 1);
    int main_params_count = 8 * l * b;
    int extra_params_count = 3 * b;
    int total_params_count = main_params_count + extra_params_count;
    MainParams<double> main_params_wrap(main_params, b, l);
    ExtraParams<double> extra_params_wrap(extra_params, b);
    State<double> state_wrap(state.data(), b, l);
    InputSequence<double> sequence_wrap(sequence, b, c);
    std::vector<double> ypred(b), lse_d(b);
    std::vector<double> grad_lse_ypred_raw(total_params_count);
    std::vector<double> prev_state_jacobian_raw(((10 * l + 1) * b) * 2 * l), state_jacobian_raw(((10 * l + 1) * b) * 2 * l), ypred_jacobian_raw((10 * l + 3) * b);
    StateJacobianPredict<double> prev_state_jacobian(prev_state_jacobian_raw.data(), l, b), state_jacobian(state_jacobian_raw.data(), l, b);
    PredictionJacobian<double> ypred_jacobian(ypred_jacobian_raw.data(), l, b);
    GradByParams<double> j_wrap(J, b, l), grad_lse_ypred(grad_lse_ypred_raw.data(), b, l);

    // temps for lstm_predict_d
    std::vector<double> zero_layer_jacobian_raw((10 * l + 1) * b);
    LayerStateJacobianPredict<double> zero_layer_jacobian(zero_layer_jacobian_raw.data(), l, b);
    ModelJacobian<double> layer_state_d(b);

    std::fill_n(J, total_params_count, 0.);

    lstm_predict_d(l, b, main_params_wrap, extra_params_wrap, state_wrap, sequence_wrap.sequence[0], zero_layer_jacobian, layer_state_d, ypred.data(), prev_state_jacobian, ypred_jacobian);

    double lse = logsumexp_d(ypred.data(), b, lse_d.data());
    logsumexp_grad(l, b, lse_d, ypred_jacobian, grad_lse_ypred);

    const double* ygold = sequence_wrap.sequence[1];

    for (int i = 0; i < b; ++i)
        total += ygold[i] * (ypred[i] - lse);

    update_loss_gradient(l, b, ygold, grad_lse_ypred, ypred_jacobian, j_wrap);

    for (int t = 1; t < c - 2; ++t)
    {
        lstm_predict_d(l, b, main_params_wrap, extra_params_wrap, state_wrap, sequence_wrap.sequence[t], zero_layer_jacobian, layer_state_d, ypred.data(), state_jacobian, ypred_jacobian);

        // Adding (D state_t / D state_(t-1)) * (D state_(t-1) / D params) to state_jacobian w.r.t. params
        update_state_jacobian_with_prev_state_jacobian(l, b, prev_state_jacobian, state_jacobian);

        // Adding (D pred / D state_(t-1)) * (D state_(t-1) / D params) to ypred_jacobian w.r.t. params
        update_pred_jacobian_with_prev_state_jacobian(l, b, prev_state_jacobian, ypred_jacobian);

        lse = logsumexp_d(ypred.data(), b, lse_d.data());
        // D logsumexp(pred) / D params
        logsumexp_grad(l, b, lse_d, ypred_jacobian, grad_lse_ypred);

        ygold = sequence_wrap.sequence[t + 1];

        for (int i = 0; i < b; ++i)
            total += ygold[i] * (ypred[i] - lse);

        update_loss_gradient(l, b, ygold, grad_lse_ypred, ypred_jacobian, j_wrap);

        swap(state_jacobian, prev_state_jacobian);
    }

    lstm_predict_d(l, b, main_params_wrap, extra_params_wrap, state_wrap, sequence_wrap.sequence[c - 2], zero_layer_jacobian, layer_state_d, ypred.data(), state_jacobian, ypred_jacobian);
    // No need to compute the jacobian for the last state
    // Adding (D pred / D state_(t-1)) * (D state_(t-1) / D params) to ypred_jacobian w.r.t. params
    update_pred_jacobian_with_prev_state_jacobian(l, b, prev_state_jacobian, ypred_jacobian);

    lse = logsumexp_d(ypred.data(), b, lse_d.data());
    // D logsumexp(pred) / D params
    logsumexp_grad(l, b, lse_d, ypred_jacobian, grad_lse_ypred);

    ygold = sequence_wrap.sequence[c - 1];

    for (int i = 0; i < b; ++i)
        total += ygold[i] * (ypred[i] - lse);

    update_loss_gradient(l, b, ygold, grad_lse_ypred, ypred_jacobian, j_wrap);

    *loss = -total / count;

    for (int i = 0; i < total_params_count; ++i)
        J[i] /= -(double)count;
}