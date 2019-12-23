# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

from __future__ import absolute_import, division, print_function, \
                       unicode_literals

import numpy as np
import tensorflow as tf
from tensorflow.python.framework.ops import disable_eager_execution

disable_eager_execution()   # turn eager execution off

from modules.TensorflowCommon.utils import to_tf_tensor, flatten
from shared.ITest import ITest
from shared.LSTMData import LSTMInput, LSTMOutput
from modules.TensorflowGraph.lstm_objective import lstm_objective



class TensorflowGraphLSTM(ITest):
    '''Test class for LSTM diferentiation by Tensorflow using computational
    graphs.'''

    def prepare(self, input):
        '''Prepares calculating. This function must be run before any others.'''

        graph = tf.compat.v1.Graph()
        with graph.as_default():
            self.main_params = input.main_params
            self.extra_params = input.extra_params
            self.state = to_tf_tensor(input.state)
            self.sequence = to_tf_tensor(input.sequence)

            self.prepare_operations()

        self.session = tf.compat.v1.Session(graph = graph)
        self.first_running()

        self.gradient = np.zeros(0)
        self.objective = np.zeros(1)

    def prepare_operations(self):
        '''Prepares computational graph for needed operations.'''

        self.main_params_placeholder = tf.compat.v1.placeholder(
            dtype = tf.float64,
            shape = self.main_params.shape
        )

        self.extra_params_placeholder = tf.compat.v1.placeholder(
            dtype = tf.float64,
            shape = self.extra_params.shape
        )

        with tf.GradientTape(persistent = True) as grad_tape:
            grad_tape.watch(self.main_params_placeholder)
            grad_tape.watch(self.extra_params_placeholder)

            self.objective_operation = lstm_objective(
                self.main_params_placeholder,
                self.extra_params_placeholder,
                self.state,
                self.sequence
            )

        J = grad_tape.gradient(
            self.objective_operation,
            ( self.main_params_placeholder, self.extra_params_placeholder )
        )
        
        self.gradient_operation = tf.concat([ flatten(d) for d in J ], 0)

        self.feed_dict = {
            self.main_params_placeholder: self.main_params,
            self.extra_params_placeholder: self.extra_params
        }

    def first_running(self):
        '''Performs the first session running.'''

        self.session.run(
            self.objective_operation,
            feed_dict = self.feed_dict
        )

        self.session.run(
            self.gradient_operation,
            feed_dict = self.feed_dict
        )

    def output(self):
        '''Returns calculation result.'''

        return LSTMOutput(self.objective, self.gradient)

    def calculate_objective(self, times):
        '''Calculates objective function many times.'''

        for _ in range(times):
            self.objective = self.session.run(
                self.objective_operation,
                feed_dict = self.feed_dict
            )

    def calculate_jacobian(self, times):
        '''Calculates objective function jacobian many times.'''

        for _ in range(times):
            self.gradient = self.session.run(
                self.gradient_operation,
                feed_dict = self.feed_dict
            )