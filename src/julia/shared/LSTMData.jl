# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

module LSTMData

export LSTMInput, LSTMOutput, empty_lstm_output, load_lstm_input

struct LSTMInput
    main_params::Matrix{Float64}
    extra_params::Matrix{Float64}
    state::Matrix{Float64}
    sequence::Matrix{Float64}
end

mutable struct LSTMOutput
    objective::Float64
    gradient::Vector{Float64}
end

empty_lstm_output() = LSTMOutput(0.0, [])

function load_lstm_input(fn::AbstractString)::LSTMInput
    open(fn) do io
        line = split(readline(io), " ")
        layer_count = parse(Int, line[1])
        char_count = parse(Int, line[2])
        char_bits = parse(Int, line[3])
        readline(io)
        main_params = hcat([parse.(Float64, split(readline(io), " ")) for i=1:2*layer_count]...)
        readline(io)
        extra_params = hcat([parse.(Float64, split(readline(io), " ")) for i=1:3]...)
        readline(io)
        state = hcat([parse.(Float64, split(readline(io), " ")) for i=1:2*layer_count]...)
        readline(io)
        sequence = hcat([parse.(Float64, split(readline(io), " ")) for i=1:char_count]...)
        return LSTMInput(main_params, extra_params, state, sequence)
    end
end

end