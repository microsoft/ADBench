# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

from __future__ import absolute_import, division, print_function, \
                       unicode_literals

import numpy as np
import tensorflow as tf
from tensorflow.python.framework.ops import disable_eager_execution

disable_eager_execution()   # turn eager execution off

from modules.TensorflowCommon.utils import to_tf_tensor, flatten, shape
from shared.ITest import ITest
from shared.HandData import HandInput, HandOutput
from modules.TensorflowCommon.hand_objective import hand_objective, \
                                                    hand_objective_complicated



class TensorflowGraphHand(ITest):
    '''Test class for Hand diferentiation by Tensorflow using computational
    graphs.'''

    def prepare(self, input):
        '''Prepares calculating. This function must be run before any others.'''
        
        self.complicated = len(input.us) > 0
        self.nrows = 3 * len(input.data.correspondences)

        graph = tf.compat.v1.Graph()
        with graph.as_default():
            if self.complicated:
                self.variables = np.append(input.us.flatten(), input.theta)
                self.params = (
                    input.data.model.bone_count,
                    input.data.model.parents,
                    to_tf_tensor(input.data.model.base_relatives),
                    to_tf_tensor(input.data.model.inverse_base_absolutes),
                    to_tf_tensor(input.data.model.base_positions),
                    tf.transpose(to_tf_tensor(input.data.model.weights)),
                    input.data.model.is_mirrored,
                    to_tf_tensor(input.data.points),
                    input.data.correspondences,
                    input.data.model.triangles
                )

                self.objective_function = hand_objective_complicated
                self.ncols = len(input.theta) + 2
            else:
                self.variables = input.theta
                self.params = (
                    input.data.model.bone_count,
                    input.data.model.parents,
                    to_tf_tensor(input.data.model.base_relatives),
                    to_tf_tensor(input.data.model.inverse_base_absolutes),
                    to_tf_tensor(input.data.model.base_positions),
                    tf.transpose(to_tf_tensor(input.data.model.weights)),
                    input.data.model.is_mirrored,
                    to_tf_tensor(input.data.points),
                    input.data.correspondences
                )

                self.objective_function = hand_objective
                self.ncols = len(input.theta)

            self.prepare_operations()

        self.session = tf.compat.v1.Session(graph = graph)
        self.first_running()

        self.objective = None
        self.jacobian = None

    def prepare_operations(self):
        '''Prepares computational graph for needed operations.'''

        self.variables_holder = tf.compat.v1.placeholder(
            dtype = tf.float64,
            shape = self.variables.shape
        )

        with tf.GradientTape(persistent = True) as grad_tape:
            grad_tape.watch(self.variables_holder)
            self.objective_operation = self.objective_function(
                self.variables_holder,
                *self.params
            )

            self.objective_operation = flatten(self.objective_operation)

        self.jacobian_operation = grad_tape.jacobian(
            self.objective_operation,
            self.variables_holder,
            experimental_use_pfor = False
        )

        self.feed_dict = { self.variables_holder: self.variables }

    def first_running(self):
        '''Performs the first session running.'''

        self.session.run(
            self.objective_operation,
            feed_dict = self.feed_dict
        )

        self.session.run(
            self.jacobian_operation,
            feed_dict = self.feed_dict
        )

    def output(self):
        '''Returns calculation result.'''

        if self.objective is None:
            self.objective = np.zeros(self.nrows, dtype = np.float64)

        if self.jacobian is None:
            self.jacobian = np.zeros(( self.nrows, self.ncols ), dtype = np.float64)

        if self.complicated:
            # Merging us part of jacobian to two columns.
            # Note: jacobian has the following structure:
            #
            #   [us_part theta_part]
            #
            # where us part is a block diagonal matrix with blocks of
            # size [3, 2]

            us_J = np.concatenate([
                self.jacobian[3 * i: 3 * i + 3, 2 * i: 2 * i + 2]
                for i in range(self.nrows // 3)
            ], 0)

            us_count = 2 * self.nrows // 3
            theta_J = self.jacobian[:, us_count:]

            self.jacobian = np.concatenate((us_J, theta_J), 1)

        return HandOutput(self.objective, self.jacobian)
    
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
            self.jacobian = self.session.run(
                self.jacobian_operation,
                feed_dict = self.feed_dict
            )