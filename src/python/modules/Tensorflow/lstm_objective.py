# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import tensorflow as tf
from modules.TensorflowCommon.utils import shape

def lstm_model(weight, bias, hidden, cell, inp):
    '''The LSTM model.'''

    gates = tf.concat(( inp, hidden, inp, hidden ), 0) * weight + bias
    hidden_size = shape(hidden)[0]

    forget = tf.math.sigmoid(gates[0: hidden_size])
    ingate = tf.math.sigmoid(gates[hidden_size: 2 * hidden_size])
    outgate = tf.math.sigmoid(gates[2 * hidden_size: 3 * hidden_size])
    change = tf.math.tanh(gates[3 * hidden_size:])

    cell = cell * forget + ingate * change
    hidden = outgate * tf.math.tanh(cell)

    return (hidden, cell)



def predict(w, w2, state, x):
    '''Predicts output given an input.'''

    new_state = []
    x = x * w2[0]

    for i in range(0, shape(state)[0], 2):
        hidden, cell = lstm_model(w[i], w[i + 1], state[i], state[i + 1], x)
        x = hidden
        new_state.append(hidden)
        new_state.append(cell)

    new_state = tf.stack(new_state, 0)
    return (x * w2[1] + w2[2], new_state)



def lstm_objective(main_params, extra_params, state, sequence):
    '''Gets the average loss for the LSTM across a sequence of inputs.'''

    total = 0.0
    count = 0
    inp = sequence[0]
    all_states = [ state ]

    for t in range(shape(sequence)[0] - 1):
        ypred, new_state = predict(
            main_params,
            extra_params,
            all_states[t],
            inp
        )

        all_states.append(new_state)
        ynorm = ypred - tf.math.log(tf.reduce_sum(tf.exp(ypred)) + 2)
        ygold = sequence[t + 1]

        total += tf.reduce_sum(ygold * ynorm)
        count += shape(ygold)[0]

        inp = ygold

    return -total / count