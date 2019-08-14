// FiniteLSTM.cpp : Defines the exported functions for the DLL.
#include "FiniteLSTM.h"
#include "../../shared/lstm.h"
#include "finite.h"

// This function must be called before any other function.
void FiniteLSTM::prepare(LSTMInput&& input)
{
    this->input = input;
    int Jcols = 8 * this->input.l * this->input.b + 3 * this->input.b;
    state = std::vector<double>(this->input.state.size());
    result = { 0, std::vector<double>(Jcols) };
    engine.set_max_output_size(1);
}

LSTMOutput FiniteLSTM::output()
{
    return result;
}

void FiniteLSTM::calculate_objective(int times)
{
    for (int i = 0; i < times; ++i) {
        state = input.state;
        lstm_objective(input.l, input.c, input.b, input.main_params.data(), input.extra_params.data(), state, input.sequence.data(), &result.objective);
    }
}

void FiniteLSTM::calculate_jacobian(int times)
{
    for (int i = 0; i < times; ++i) {
        state = input.state;
        // separately computing objective, because central differences won't compute it along the way
        lstm_objective(input.l, input.c, input.b, input.main_params.data(), input.extra_params.data(), state, input.sequence.data(), &result.objective);

        engine.finite_differences([&](double* main_params_in, double* loss) {
            lstm_objective(input.l, input.c, input.b, main_params_in,
                input.extra_params.data(), state, input.sequence.data(), loss);
            }, input.main_params.data(), input.main_params.size(), 1, result.gradient.data());

        engine.finite_differences([&](double* extra_params_in, double* loss) {
            lstm_objective(input.l, input.c, input.b, input.main_params.data(),
                extra_params_in, state, input.sequence.data(), loss);
            }, input.extra_params.data(), input.extra_params.size(), 1, &result.gradient.data()[2 * input.l * 4 * input.b]);
    }
}

extern "C" DLL_PUBLIC ITest<LSTMInput, LSTMOutput>*  get_lstm_test()
{
    return new FiniteLSTM();
}
