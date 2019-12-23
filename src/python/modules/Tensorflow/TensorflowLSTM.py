# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

from __future__ import absolute_import, division, print_function, \
                       unicode_literals

import tensorflow as tf

from modules.TensorflowCommon.utils import to_tf_tensor, flatten
from shared.ITest import ITest
from shared.LSTMData import LSTMInput, LSTMOutput
from modules.Tensorflow.lstm_objective import lstm_objective



class TensorflowLSTM(ITest):
    '''Test class for LSTM diferentiation by Tensorflow using eager
    execution.'''

    def prepare(self, input):
        '''Prepares calculating. This function must be run before any others.'''

        self.main_params = to_tf_tensor(input.main_params)
        self.extra_params = to_tf_tensor(input.extra_params)
        self.state = to_tf_tensor(input.state)
        self.sequence = to_tf_tensor(input.sequence)

        self.gradient = tf.zeros(0)
        self.objective = tf.zeros(1)

    def output(self):
        '''Returns calculation result.'''

        return LSTMOutput(self.objective.numpy(), self.gradient.numpy())

    def calculate_objective(self, times):
        '''Calculates objective function many times.'''

        for _ in range(times):
            self.objective = lstm_objective(
                self.main_params,
                self.extra_params,
                self.state,
                self.sequence
            )

    def calculate_jacobian(self, times):
        ''' Calculates objective function jacobian many times.'''

        for _ in range(times):
            with tf.GradientTape(persistent = True) as t:
                t.watch(self.main_params)
                t.watch(self.extra_params)

                self.objective = lstm_objective(
                    self.main_params,
                    self.extra_params,
                    self.state,
                    self.sequence
                )

            J = t.gradient(self.objective, (self.main_params, self.extra_params))
            self.gradient = tf.concat([ flatten(d) for d in J ], 0)