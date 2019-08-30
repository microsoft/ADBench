#include "TapenadeLSTM.h"

void TapenadeLSTM::prepare(LSTMInput&& input)
{
    this->input = input;
    state = std::vector<double>(this->input.state.size());

    int Jcols = 8 * this->input.l * this->input.b + 3 * this->input.b;
    result = { 0, std::vector<double>(Jcols) };
}



LSTMOutput TapenadeLSTM::output()
{
    return result;
}



void TapenadeLSTM::calculate_objective(int times)
{
    for (int i = 0; i < times; i++)
    {
        state = input.state;
        lstm_objective(
            input.l,
            input.c,
            input.b,
            input.main_params.data(),
            input.extra_params.data(),
            state.data(),
            input.sequence.data(),
            &result.objective
        );
    }
}



void TapenadeLSTM::calculate_jacobian(int times)
{
    double loss = 0.0;      // stores fictive result
                            // (Tapenade doesn't calculate an original function in reverse mode)

    double lossb = 1.0;     // stores dY
                            // (equals to 1.0 for gradient calculation)

    double* main_params_gradient_part = result.gradient.data();
    double* extra_params_gradient_part = result.gradient.data() + input.main_params.size();

    for (int i = 0; i < times; i++)
    {
        state = input.state;
        lstm_objective_b(
            input.l,
            input.c,
            input.b,
            input.main_params.data(),
            main_params_gradient_part,
            input.extra_params.data(),
            extra_params_gradient_part,
            state.data(),
            input.sequence.data(),
            &loss,
            &lossb
        );
    }
}



extern "C" DLL_PUBLIC ITest<LSTMInput, LSTMOutput>* get_lstm_test()
{
    return new TapenadeLSTM();
}