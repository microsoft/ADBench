module LSTMData

export LSTMInput, LSTMOutput, empty_lstm_output

struct LSTMInput
    main_params::Vector{Float64}
    extra_params::Vector{Float64}
    state::Vector{Float64}
    sequence::Vector{Float64}
end

mutable struct LSTMOutput
    objective::Float64
    gradient::Vector{Float64}
end

empty_lstm_output() = LSTMOutput(0.0, [])

end