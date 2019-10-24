from __future__ import absolute_import, division, print_function, \
                       unicode_literals
 
# By some reason TF 2.0 produces a lot of messages of the following type:
#
#       2019-10-22 19:08:15.313154: E tensorflow/core/common_runtime/executor.cc:642] Executor failed to create kernel. Internal: No function library
#           [[{{node loop_body/MatMul_111/pfor/cond}}]]
#
# Possible source of these messages is function 'euler_angles_to_rotation_matrix'
# in the file 'hand_objective.py' of the current directory.
#
# A similar problem is described in issue https://github.com/tensorflow/tensorflow/issues/32460
# Such errors don't affect on result correctness, so, they are just turned off.
import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'    # turn TF warnings off

import tensorflow as tf
import numpy as np

from modules.Tensorflow.utils import to_tf_tensor, flatten, shape
from shared.ITest import ITest
from shared.HandData import HandInput, HandOutput
from modules.Tensorflow.hand_objective import hand_objective, \
                                              hand_objective_complicated



class TensorflowHand(ITest):
    '''Test class for hand tracking function differentiation by Tensorflow.'''

    def prepare(self, input):
        '''Prepares calculating. This function must be run before
        any others.'''

        self.complicated = len(input.us) > 0
        self.nrows = 3 * len(input.data.correspondences)

        if self.complicated:
            self.variables = to_tf_tensor(
                np.append(input.us.flatten(), input.theta)
            )

            self.params = (
                input.data.model.bone_count,
                to_tf_tensor(input.data.model.parents, dtype = tf.int32),
                to_tf_tensor(input.data.model.base_relatives),
                to_tf_tensor(input.data.model.inverse_base_absolutes),
                to_tf_tensor(input.data.model.base_positions),
                to_tf_tensor(input.data.model.weights),
                input.data.model.is_mirrored,
                to_tf_tensor(input.data.points),
                to_tf_tensor(
                    input.data.correspondences,
                    dtype = tf.int32
                ),
                input.data.model.triangles
            )

            self.objective_function = hand_objective_complicated
            self.ncols = len(input.theta) + 2
        else:
            self.variables = to_tf_tensor(input.theta)
            self.params = (
                input.data.model.bone_count,
                to_tf_tensor(input.data.model.parents, dtype = tf.int32),
                to_tf_tensor(input.data.model.base_relatives),
                to_tf_tensor(input.data.model.inverse_base_absolutes),
                to_tf_tensor(input.data.model.base_positions),
                to_tf_tensor(input.data.model.weights),
                input.data.model.is_mirrored,
                to_tf_tensor(input.data.points),
                to_tf_tensor(input.data.correspondences, dtype = tf.int32)
            )

            self.objective_function = hand_objective
            self.ncols = len(input.theta)

        self.objective = None
        self.jacobian = None

    def output(self):
        '''Returns calculation result.'''

        if self.objective is None:
            self.objective = tf.zeros(self.nrows, dtype = tf.float64)

        if self.jacobian is None:
            self.jacobian = tf.zeros(( self.nrows, self.ncols ), dtype = tf.float64)

        if self.complicated:
            # Merging us part of jacobian to two columns.
            # Note: jacobian has the following structure:
            #
            #   [us_part theta_part]
            #
            # where us part is a block diagonal matrix with blocks of
            # size [3, 2]

            us_J = tf.concat([
                self.jacobian[3 * i: 3 * i + 3, 2 * i: 2 * i + 2]
                for i in range(self.nrows // 3)
            ], 0)

            us_count = 2 * self.nrows // 3
            theta_J = self.jacobian[:, us_count:]

            self.jacobian = tf.concat((us_J, theta_J), 1)

        return HandOutput(self.objective.numpy(), self.jacobian.numpy())
    
    def calculate_objective(self, times):
        '''Calculates objective function many times.'''

        for _ in range(times):
            self.objective = self.objective_function(
                self.variables,
                *self.params
            )

            self.objective = flatten(self.objective)

    def calculate_jacobian(self, times):
        '''Calculates objective function jacobian many times.'''

        for _ in range(times):
            with tf.GradientTape(persistent = True) as t:
                t.watch(self.variables)

                self.objective = self.objective_function(
                    self.variables,
                    *self.params
                )

                self.objective = flatten(self.objective)

            self.jacobian = t.jacobian(self.objective, self.variables)