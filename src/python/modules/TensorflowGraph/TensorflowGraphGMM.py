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
from shared.GMMData import GMMInput, GMMOutput
from modules.TensorflowCommon.gmm_objective import gmm_objective



class TensorflowGraphGMM(ITest):
    '''Test class for GMM diferentiation by Tensorflow using computational
    graphs.'''

    def prepare(self, input):
        '''Prepares calculating. This function must be run before
        any others.'''

        self.alphas = input.alphas
        self.means = input.means
        self.icf = input.icf

        graph = tf.compat.v1.Graph()
        with graph.as_default():
            self.x = to_tf_tensor(input.x)
            self.wishart_gamma = input.wishart.gamma
            self.wishart_m = input.wishart.m

            self.prepare_operations()

        self.session = tf.compat.v1.Session(graph = graph)
        self.first_running()

        self.objective = np.zeros(1)
        self.gradient = np.zeros(0)

    def prepare_operations(self):
        '''Prepares computational graph for needed operations.'''

        self.alphas_placeholder = tf.compat.v1.placeholder(
            dtype = tf.float64,
            shape = self.alphas.shape
        )

        self.means_placeholder = tf.compat.v1.placeholder(
            dtype = tf.float64,
            shape = self.means.shape
        )

        self.icf_placeholder = tf.compat.v1.placeholder(
            dtype = tf.float64,
            shape = self.icf.shape
        )

        with tf.GradientTape(persistent = True) as grad_tape:
            grad_tape.watch(self.alphas_placeholder)
            grad_tape.watch(self.means_placeholder)
            grad_tape.watch(self.icf_placeholder)

            self.objective_operation = gmm_objective(
                self.alphas_placeholder,
                self.means_placeholder,
                self.icf_placeholder,
                self.x,
                self.wishart_gamma,
                self.wishart_m
            )

        J = grad_tape.gradient(
            self.objective_operation,
            (
                self.alphas_placeholder,
                self.means_placeholder,
                self.icf_placeholder
            )
        )

        self.gradient_operation = tf.concat([ flatten(d) for d in J ], 0)

        self.feed_dict = {
            self.alphas_placeholder: self.alphas,
            self.means_placeholder: self.means,
            self.icf_placeholder: self.icf
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

        return GMMOutput(self.objective, self.gradient)

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