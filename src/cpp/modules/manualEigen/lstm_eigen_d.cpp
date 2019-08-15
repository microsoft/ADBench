#include "lstm_eigen_d.h"
#include "lstm_eigen_d_structures.h"
#include "../../shared/lstm_eigen.h"

// UTILS

// Sigmoid diff on vector
template<typename T>
ArrayX<T> sigmoid_d(const ArrayX<T>& x, ArrayX<T>& d) {
    ArrayX<T> s = sigmoid(x);
    d.resize(s.rows()); //DANGER may be incorrect size
    d = s * (1 - s);
    return s;
}

// tanh diff on vector
template<typename T>
ArrayX<T> tanh_d(const ArrayX<T>& x, ArrayX<T>& d) {
    ArrayX<T> t = tanh(x);
    d.resize(t.rows()); //DANGER may be incorrect size
    d = 1 - t * t;
    return t;
}

// value (returned) and gradient (written to J) of log(sum(exp(x), 2))
template<typename T>
T logsumexp_d(const ArrayX<T>& vect, ArrayX<T>& J) {
    J = exp(vect);
    T sum = J.sum();
    sum += 2.;

    J /= sum;
    return log(sum);
}

template<typename T>
void swap_new(StateJacobianPredictNew<T>& j1, StateJacobianPredictNew<T>& j2)
{
    j1.layer.swap(j2.layer);
}

// OBJECTIVE

// Manual Jacobian of lstm_model
// Outputs jacobian containing the derivatives of the new state
// with relation to params, state, and input
template<typename T>
void lstm_model_d_new(int hsize,
    const LayerParams<T>& params,
    LayerState<T>& state,
    const ArrayX<T>& input,
    ModelJacobianNew<T>& jacobian)
{
    ArrayX<T> forget_in(input * params.weight.forget + params.bias.forget);
    ArrayX<T> forget_sd;
    ArrayX<T> forget(sigmoid_d(forget_in, forget_sd));
    ArrayX<T> forget_dw(forget_sd * input);
    ArrayX<T> forget_db(forget_sd);
    ArrayX<T> forget_di(forget_sd * params.weight.forget);

    ArrayX<T> ingate_in(state.hidden * params.weight.ingate + params.bias.ingate);
    ArrayX<T> ingate_sd;
    ArrayX<T> ingate(sigmoid_d(ingate_in, ingate_sd));
    ArrayX<T> ingate_dw(ingate_sd * state.hidden);
    ArrayX<T> ingate_db(ingate_sd);
    ArrayX<T> ingate_dh(ingate_sd * params.weight.ingate);

    ArrayX<T> outgate_in(input * params.weight.outgate + params.bias.outgate);
    ArrayX<T> outgate_sd;
    ArrayX<T> outgate(sigmoid_d(outgate_in, outgate_sd));
    ArrayX<T> outgate_dw(outgate_sd * input);
    ArrayX<T> outgate_db(outgate_sd);
    ArrayX<T> outgate_di(outgate_sd * params.weight.outgate);

    ArrayX<T> change_in(state.hidden * params.weight.change + params.bias.change);
    ArrayX<T> change_td;
    ArrayX<T> change(tanh_d(change_in, change_td));
    ArrayX<T> change_dw(change_td * state.hidden);
    ArrayX<T> change_db(change_td);
    ArrayX<T> change_dh(change_td * params.weight.change);

    // Cell derivatives

    ArrayX<T> orig_cell = state.cell;
    state.cell = orig_cell * forget + ingate * change;
    // wrt weight
    jacobian.cell.d_rawX10.col(0) = orig_cell * forget_dw;
    jacobian.cell.d_rawX10.col(1) = change * ingate_dw;
    jacobian.cell.d_rawX10.col(2) = 0.;
    jacobian.cell.d_rawX10.col(3) = ingate * change_dw;
    // wrt bias
    jacobian.cell.d_rawX10.col(4) = orig_cell * forget_db;
    jacobian.cell.d_rawX10.col(5) = change * ingate_db;
    jacobian.cell.d_rawX10.col(6).setZero();
    jacobian.cell.d_rawX10.col(7) = ingate * change_db;
    // wrt hidden, cell(original), input
    jacobian.cell.d_rawX10.col(8) = ingate * change_dh + change * ingate_dh;
    jacobian.cell.d_rawX10.col(9) = forget;
    jacobian.cell.d_input = orig_cell * forget_di;

    // Hidden derivatives
    ArrayX<T> hidden_td;
    ArrayX<T> hidden_t = tanh_d((ArrayX<T>)state.cell, hidden_td);
    state.hidden = outgate * hidden_t;
    hidden_td *= outgate;
    // wrt weight
    jacobian.hidden.d_rawX10.col(0) = hidden_td * jacobian.cell.d_rawX10.col(0);
    jacobian.hidden.d_rawX10.col(1) = hidden_td * jacobian.cell.d_rawX10.col(1);
    jacobian.hidden.d_rawX10.col(2) = hidden_t * outgate_dw;
    jacobian.hidden.d_rawX10.col(3) = hidden_td * jacobian.cell.d_rawX10.col(3);
    // wrt bias
    jacobian.hidden.d_rawX10.col(4) = hidden_td * jacobian.cell.d_rawX10.col(4);
    jacobian.hidden.d_rawX10.col(5) = hidden_td * jacobian.cell.d_rawX10.col(5);
    jacobian.hidden.d_rawX10.col(6) = hidden_t * outgate_db;
    jacobian.hidden.d_rawX10.col(7) = hidden_td * jacobian.cell.d_rawX10.col(7);
    // wrt hidden, cell (original), input
    jacobian.hidden.d_rawX10.col(8) = hidden_td * jacobian.cell.d_rawX10.col(8);
    jacobian.hidden.d_rawX10.col(9) = hidden_td * jacobian.cell.d_rawX10.col(9);
    jacobian.hidden.d_input = outgate_di * hidden_t + hidden_td * jacobian.cell.d_input;
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
void lstm_predict_d_new(int l, int b,
    const MainParams<T>& main_params, const ExtraParams<T>& extra_params,
    State<T>& state,
    const ArrayX<T>& input,
    LayerStateJacobianPredictNew<T>& zero_layer_jacobian,
    ModelJacobianNew<T>& layer_state_d,
    ArrayX<T>& output,
    StateJacobianPredictNew<T>& state_jacobian,
    PredictionJacobianNew<T>& output_jacobian)
{
    // Intial setup (from predict())
    output = input * extra_params.in_weight;
    for (int i = 0; i < b; ++i) {
        // note that the rest of zero_layer_jacobian.d_hidden and zero_layer_jacobian.d_cell are unused
        *zero_layer_jacobian.d_hidden[i].d_extra_in_weight = input[i];
    }

    // Pointer to current output/next layer's input
    ArrayX<T> layer_output = output;
    // Pointer to the jacobian of the previous layer
    LayerStateJacobianPredictNew<T>* prev_layer_jacobian = &zero_layer_jacobian;

    // Main LSTM loop (from predict())
    for (int i = 0; i < l; ++i)
    {
        lstm_model_d_new(b, main_params.layer_params[i], state.layer_state[i], layer_output, layer_state_d);
        layer_output = state.layer_state[i].hidden;

        // set state_jacobian.layer[i]
        for (int j = 0; j < b; ++j)
        {
            T hidden_j_d_input = layer_state_d.hidden.d_input[j];
            T cell_j_d_input = layer_state_d.cell.d_input[j];
            // derivatives by variables on which layer_output depends
            *state_jacobian.layer[i].d_hidden[j].d_extra_in_weight = hidden_j_d_input * (*prev_layer_jacobian->d_hidden[j].d_extra_in_weight);
            *state_jacobian.layer[i].d_cell[j].d_extra_in_weight = cell_j_d_input * (*prev_layer_jacobian->d_hidden[j].d_extra_in_weight);
            state_jacobian.layer[i].d_hidden[j].d_rawX10.topRows(i) = hidden_j_d_input * prev_layer_jacobian->d_hidden[j].d_rawX10.topRows(i);
            state_jacobian.layer[i].d_cell[j].d_rawX10.topRows(i) = cell_j_d_input * prev_layer_jacobian->d_hidden[j].d_rawX10.topRows(i);
            // derivatives by variables on which lstm_model_d depends directly
            state_jacobian.layer[i].d_hidden[j].d_rawX10.row(i) = layer_state_d.hidden.d_rawX10.row(j);
            state_jacobian.layer[i].d_cell[j].d_rawX10.row(i) = layer_state_d.cell.d_rawX10.row(j);
            // derivatives by variable on which lstm_model_d does not depend (zero)
            state_jacobian.layer[i].d_hidden[j].d_rawX10.bottomRows(l - i - 1).setZero();
            state_jacobian.layer[i].d_cell[j].d_rawX10.bottomRows(l - i - 1).setZero();
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

        output_jacobian.d_prediction[i].d_rawX10 = cur_out_weight * prev_layer_jacobian->d_hidden[i].d_rawX10;
    }
}

// Gradient of the logsumexp(prediction(params)) with relation to params
void logsumexp_grad_new(int n_layers, int hsize,
    const ArrayX<double>& lse_d,
    const PredictionJacobianNew<double>& ypred_jacobian,
    GradByParamsNew<double>& grad_lse_ypred)
{
    for (int i = 0; i < hsize; ++i)
    {
        double lse_d_i = lse_d[i];
        for (int j = 0; j < n_layers; ++j)
        {
            grad_lse_ypred.layer[j].d_params.row(i) = lse_d_i * ypred_jacobian.d_prediction[i].d_rawX8.row(j);

            //grad_lse_ypred.layer[j].d_weight.forget[i] = lse_d_i * ypred_jacobian.d_prediction[i].d_weight_forget[j];
            //grad_lse_ypred.layer[j].d_weight.ingate[i] = lse_d_i * ypred_jacobian.d_prediction[i].d_weight_ingate[j];
            //grad_lse_ypred.layer[j].d_weight.outgate[i] = lse_d_i * ypred_jacobian.d_prediction[i].d_weight_outgate[j];
            //grad_lse_ypred.layer[j].d_weight.change[i] = lse_d_i * ypred_jacobian.d_prediction[i].d_weight_change[j];
            //grad_lse_ypred.layer[j].d_bias.forget[i] = lse_d_i * ypred_jacobian.d_prediction[i].d_bias_forget[j];
            //grad_lse_ypred.layer[j].d_bias.ingate[i] = lse_d_i * ypred_jacobian.d_prediction[i].d_bias_ingate[j];
            //grad_lse_ypred.layer[j].d_bias.outgate[i] = lse_d_i * ypred_jacobian.d_prediction[i].d_bias_outgate[j];
            //grad_lse_ypred.layer[j].d_bias.change[i] = lse_d_i * ypred_jacobian.d_prediction[i].d_bias_change[j];
        }
        grad_lse_ypred.d_in_out.row(i) = lse_d_i * ypred_jacobian.d_prediction[i].d_extra_in_out;
        //grad_lse_ypred.d_in_weight[i] = lse_d_i * (*ypred_jacobian.d_prediction[i].d_extra_in_weight);
        //grad_lse_ypred.d_out_weight[i] = lse_d_i * (*ypred_jacobian.d_prediction[i].d_extra_out_weight);
        //grad_lse_ypred.d_out_bias[i] = lse_d_i * (*ypred_jacobian.d_prediction[i].d_extra_out_bias);
    }
}

// Updates the gradient of the loss function (loss_grad) after doing a prediction
// using the gold value for the prediction (ygold),
// jacobian of the prediction with relation to params (ypred_jacobian),
// and the gradient of the logsumexp(prediction(params)) with relation to params (grad_lse_ypred)
void update_loss_gradient_new(int n_layers, int hsize,
    const ArrayX<double>& ygold,
    const GradByParamsNew<double>& grad_lse_ypred,
    const PredictionJacobianNew<double>& ypred_jacobian,
    GradByParamsNew<double>& loss_grad)
{
    for (int i = 0; i < hsize; ++i)
    {
        double ygold_i = ygold[i];

        for (int k = 0; k < n_layers; ++k)
        {
            loss_grad.layer[k].d_params.topRows(i) -= ygold_i * grad_lse_ypred.layer[k].d_params.topRows(i);
            loss_grad.layer[k].d_params.row(i) += ygold_i * (ypred_jacobian.d_prediction[i].d_rawX8.row(k) -
                grad_lse_ypred.layer[k].d_params.row(i));
            loss_grad.layer[k].d_params.bottomRows(hsize - i - 1) -= ygold_i *
                grad_lse_ypred.layer[k].d_params.bottomRows(hsize - i - 1);
        }

        loss_grad.d_in_out.topRows(i) -= ygold_i * grad_lse_ypred.d_in_out.topRows(i);
        loss_grad.d_in_out.row(i) += ygold_i * (MapRow3<double>(ypred_jacobian.d_prediction[i].d_extra_in_weight, 3) -
            grad_lse_ypred.d_in_out.row(i));
        loss_grad.d_in_out.bottomRows(hsize - i - 1) -= ygold_i * grad_lse_ypred.d_in_out.bottomRows(hsize - i - 1);
    }
}

// Add (D pred / D state_(t-1)) * (D state_(t-1) / D params) to ypred_jacobian with relation to params
void update_pred_jacobian_with_prev_state_jacobian_new(int n_layers, int hsize,
    const StateJacobianPredictNew<double>& prev_state_jacobian,
    PredictionJacobianNew<double>& ypred_jacobian)
{
    for (int pos = 0; pos < hsize; ++pos)
    {
        for (int i = 0; i < n_layers; ++i)
        {
            ypred_jacobian.d_prediction[pos].d_rawX8 +=
                ypred_jacobian.d_prediction[pos].d_hidden[i] * prev_state_jacobian.layer[i].d_hidden[pos].d_rawX8
                + ypred_jacobian.d_prediction[pos].d_cell[i] * prev_state_jacobian.layer[i].d_cell[pos].d_rawX8;

            *ypred_jacobian.d_prediction[pos].d_extra_in_weight +=
                ypred_jacobian.d_prediction[pos].d_hidden[i] * (*prev_state_jacobian.layer[i].d_hidden[pos].d_extra_in_weight)
                + ypred_jacobian.d_prediction[pos].d_cell[i] * (*prev_state_jacobian.layer[i].d_cell[pos].d_extra_in_weight);
        }
    }
}

// Add (D state_t / D state_(t-1)) * (D state_(t-1) / D params) to state_jacobian with relation to params
void update_state_jacobian_with_prev_state_jacobian_new(int n_layers, int hsize,
    const StateJacobianPredictNew<double>& prev_state_jacobian,
    StateJacobianPredictNew<double>& state_jacobian)
{
    for (int pos = 0; pos < hsize; ++pos)
    {
        for (int i = 0; i < n_layers; ++i)
        {
            for (int j = 0; j < n_layers; ++j)
            {
                state_jacobian.layer[i].d_hidden[pos].d_rawX8 +=
                    state_jacobian.layer[i].d_hidden[pos].d_hidden[j] * prev_state_jacobian.layer[j].d_hidden[pos].d_rawX8
                    + state_jacobian.layer[i].d_hidden[pos].d_cell[j] * prev_state_jacobian.layer[j].d_cell[pos].d_rawX8;
                state_jacobian.layer[i].d_cell[pos].d_rawX8 +=
                    state_jacobian.layer[i].d_cell[pos].d_hidden[j] * prev_state_jacobian.layer[j].d_hidden[pos].d_rawX8
                    + state_jacobian.layer[i].d_cell[pos].d_cell[j] * prev_state_jacobian.layer[j].d_cell[pos].d_rawX8;

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
    ArrayX<double> ypred(b), lse_d(b);
    StateJacobianPredictNew<double> prev_state_jacobian_new(l, b), state_jacobian_new(l, b);
    PredictionJacobianNew<double> ypred_jacobian_new(l, b);
    GradByParamsNew<double> j_wrap_new(J, l, b), grad_lse_ypred_new(l, b);

    // temps for lstm_predict_d
    LayerStateJacobianPredictNew<double> zero_layer_jacobian_new(l, b);
    ModelJacobianNew<double> layer_state_d_new(b);

    std::fill_n(J, total_params_count, 0.);

    lstm_predict_d_new(l, b, main_params_wrap, extra_params_wrap, state_wrap, sequence_wrap.sequence[0],
        zero_layer_jacobian_new, layer_state_d_new, ypred, prev_state_jacobian_new, ypred_jacobian_new);

    double lse = logsumexp_d(ypred, lse_d);
    logsumexp_grad_new(l, b, lse_d, ypred_jacobian_new, grad_lse_ypred_new);

    ArrayX<double> ygold = sequence_wrap.sequence[1];

    total += (ygold * (ypred - lse)).sum();

    update_loss_gradient_new(l, b, ygold, grad_lse_ypred_new, ypred_jacobian_new, j_wrap_new);

    for (int t = 1; t < c - 2; ++t)
    {
        lstm_predict_d_new(l, b, main_params_wrap, extra_params_wrap, state_wrap, sequence_wrap.sequence[t],
            zero_layer_jacobian_new, layer_state_d_new, ypred, state_jacobian_new, ypred_jacobian_new);

        // Adding (D state_t / D state_(t-1)) * (D state_(t-1) / D params) to state_jacobian w.r.t. params
        update_state_jacobian_with_prev_state_jacobian_new(l, b, prev_state_jacobian_new, state_jacobian_new);

        // Adding (D pred / D state_(t-1)) * (D state_(t-1) / D params) to ypred_jacobian w.r.t. params
        update_pred_jacobian_with_prev_state_jacobian_new(l, b, prev_state_jacobian_new, ypred_jacobian_new);

        lse = logsumexp_d(ypred, lse_d);
        // D logsumexp(pred) / D params
        logsumexp_grad_new(l, b, lse_d, ypred_jacobian_new, grad_lse_ypred_new);

        ygold = sequence_wrap.sequence[t + 1];

        total += (ygold * (ypred - lse)).sum();

        update_loss_gradient_new(l, b, ygold, grad_lse_ypred_new, ypred_jacobian_new, j_wrap_new);

        swap_new(state_jacobian_new, prev_state_jacobian_new);
    }

    lstm_predict_d_new(l, b, main_params_wrap, extra_params_wrap, state_wrap, sequence_wrap.sequence[c - 2],
        zero_layer_jacobian_new, layer_state_d_new, ypred, state_jacobian_new, ypred_jacobian_new);
    // No need to compute the jacobian for the last state
    // Adding (D pred / D state_(t-1)) * (D state_(t-1) / D params) to ypred_jacobian w.r.t. params
    update_pred_jacobian_with_prev_state_jacobian_new(l, b, prev_state_jacobian_new, ypred_jacobian_new);

    lse = logsumexp_d(ypred, lse_d);
    // D logsumexp(pred) / D params
    logsumexp_grad_new(l, b, lse_d, ypred_jacobian_new, grad_lse_ypred_new);

    ygold = sequence_wrap.sequence[c - 1];

    total += (ygold * (ypred - lse)).sum();

    update_loss_gradient_new(l, b, ygold, grad_lse_ypred_new, ypred_jacobian_new, j_wrap_new);

    *loss = -total / count;

    for (int i = 0; i < total_params_count; ++i)
        J[i] /= -(double)count;
}