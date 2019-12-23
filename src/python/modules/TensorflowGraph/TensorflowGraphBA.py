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
from shared.BAData import BAInput, BAOutput
from shared.BASparseMat import BASparseMat
from modules.TensorflowCommon.ba_objective import compute_reproj_err, compute_w_err



class TensorflowGraphBA(ITest):
    '''Test class for BA diferentiation by Tensorflow using computational
    graphs.'''

    def prepare(self, input):
        '''Prepares calculating. This function must be run before any others.'''

        self.p = len(input.obs)

        self.cams = input.cams
        self.x = input.x
        self.w = input.w
        self.obs = input.obs
        self.feats = input.feats

        graph = tf.compat.v1.Graph()
        with graph.as_default():
            self.prepare_operations()

        self.session = tf.compat.v1.Session(graph = graph)
        self.first_running()

        self.r_err = np.zeros(2 * self.p, dtype = np.float64)
        self.w_err = np.zeros(len(input.w))
        self.jacobian = BASparseMat(len(input.cams), len(input.x), self.p)
    
    def prepare_operations(self):
        '''Prepares computational graph for needed operations.'''

        # creating holders for storing needed input for calculating a part of
        # the BA objective and its derivative (the current camera, point,
        # weight, and feat)
        self.cam_holder = tf.compat.v1.placeholder(
            dtype = tf.float64,
            shape = self.cams[0].shape
        )

        self.x_holder = tf.compat.v1.placeholder(
            dtype = tf.float64,
            shape = self.x[0].shape
        )

        self.w_holder = tf.compat.v1.placeholder(
            dtype = tf.float64,
            shape = self.w[0].shape
        )

        self.feat_holder = tf.compat.v1.placeholder(
            dtype = tf.float64,
            shape = self.feats[0].shape
        )

        self.create_operations()

    def create_operations(self):
        '''Creates operations for calculating the part of the objective and its
        derivative.'''

        with tf.GradientTape(persistent = True) as grad_tape:
            grad_tape.watch(self.cam_holder)
            grad_tape.watch(self.x_holder)
            grad_tape.watch(self.w_holder)

            self.w_err_operation = compute_w_err(self.w_holder)
            self.r_err_operation = compute_reproj_err(
                self.cam_holder,
                self.x_holder,
                self.w_holder,
                self.feat_holder
            )

        dc, dx, dw = grad_tape.jacobian(
            self.r_err_operation,
            (
                self.cam_holder,
                self.x_holder,
                self.w_holder
            ),
            experimental_use_pfor = False
        )

        self.r_err_grad_operation = flatten(
            tf.concat(( dc, dx, tf.reshape(dw, [2, 1]) ), axis = 1),
            column_major = True
        )

        self.w_err_grad_operation = grad_tape.gradient(
            self.w_err_operation,
            self.w_holder
        )

    def first_running(self):
        '''Performs the first session running.'''

        self.session.run(
            (
                self.w_err_operation,
                self.r_err_operation
            ),
            feed_dict = self.get_feed_dict(0)
        )

        self.session.run(
            (
                self.w_err_grad_operation,
                self.r_err_grad_operation
            ),
            feed_dict = self.get_feed_dict(0)
        )

    def output(self):
        '''Returns calculation result.'''

        return BAOutput(self.r_err, self.w_err, self.jacobian)

    def get_feed_dict(self, i):
        '''Returns feed dictionary for the needed jacobian part calculation.'''

        return {
            self.cam_holder: self.cams[self.obs[i, 0]],
            self.x_holder: self.x[self.obs[i, 1]],
            self.w_holder: self.w[i],
            self.feat_holder: self.feats[i]
        }

    def calculate_objective(self, times):
        '''Calculates objective function many times.'''

        for _ in range(times):
            # calculate reprojection and weight error part by part and
            # then combine the parts together
            result = tuple(
                self.session.run(
                    (
                        self.r_err_operation,
                        self.w_err_operation
                    ),
                    feed_dict = self.get_feed_dict(i)
                )
                for i in range(self.p)
            )

            result = zip(*result)
            self.r_err = np.concatenate(result.__next__(), 0)
            self.w_err = np.stack(result.__next__(), 0)

    def calculate_jacobian(self, times):
        ''' Calculates objective function jacobian many times.'''

        for _ in range(times):
            # calculate reprojection and weight error derivatives part by
            # part. Note, that weight error should be added to the sparse
            # matrix only after the last reprojection error jacobian part
            # adding, otherwise the result will be wrong
            dws = []
            for i in range(self.p):
                dr, dw = self.session.run(
                    (
                        self.r_err_grad_operation,
                        self.w_err_grad_operation
                    ),
                    feed_dict = self.get_feed_dict(i)
                )

                self.jacobian.insert_reproj_err_block(
                    i,
                    self.obs[i, 0],
                    self.obs[i, 1],
                    dr
                )

                dws.append(dw)

            for i in range(self.p):
                self.jacobian.insert_w_err_block(i, dws[i])