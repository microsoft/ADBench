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

        self.prepare_operations()

        self.reproj_error = np.zeros(2 * self.p, dtype = np.float64)
        self.w_err = np.zeros(len(input.w))
        self.jacobian = BASparseMat(len(input.cams), len(input.x), self.p)
    
    def prepare_operations(self):
        '''Prepares computational graph for needed operations.'''

        self.create_placeholders()
        self.create_operations()
        self.create_feed_dict()

    def create_placeholders(self):
        '''Creates placeholders for inputs.'''

        self.cam_holders = tuple(
            tf.compat.v1.placeholder(dtype = tf.float64, shape = cam.shape)
            for cam in self.cams
        )

        self.x_holders = tuple(
            tf.compat.v1.placeholder(dtype = tf.float64, shape = x.shape)
            for x in self.x
        )

        self.w_holders = tuple(
            tf.compat.v1.placeholder(dtype = tf.float64, shape = w.shape)
            for w in self.w
        )

    def create_operations(self):
        '''Creates operations for calculating the objective and its
        derivative.'''

        r_err_operations = []
        w_err_operations = []
        self.r_err_grad_operations = []
        self.w_err_grad_operations = []

        with tf.GradientTape(persistent = True) as grad_tape:
            for i in range(self.p):
                camIdx = self.obs[i, 0]
                ptIdx = self.obs[i, 1]

                grad_tape.watch(self.cam_holders[camIdx])
                grad_tape.watch(self.x_holders[ptIdx])
                grad_tape.watch(self.w_holders[i])

                reproj_err = compute_reproj_err(
                    self.cam_holders[camIdx],
                    self.x_holders[ptIdx],
                    self.w_holders[i],
                    self.feats[i]
                )

                w_err = compute_w_err(self.w_holders[i])

                r_err_operations.append(reproj_err)
                w_err_operations.append(w_err)

        for i in range(self.p):
            camIdx = self.obs[i, 0]
            ptIdx = self.obs[i, 1]
            dc, dx, dw = grad_tape.jacobian(
                r_err_operations[i],
                (
                    self.cam_holders[camIdx],
                    self.x_holders[ptIdx],
                    self.w_holders[i]
                ),
                experimental_use_pfor = False
            )

            J = tf.concat(( dc, dx, tf.reshape(dw, [2, 1]) ), axis = 1)
            self.r_err_grad_operations.append(flatten(J, column_major = True))

            dw_err = grad_tape.gradient(
                w_err_operations[i],
                self.w_holders[i]
            )

            self.w_err_grad_operations.append(dw_err)

        self.reproj_err_operations = tf.concat(r_err_operations, 0)
        self.w_err_operations = tf.stack(w_err_operations, 0)

    def create_feed_dict(self):
        '''Creates feed dictionary for the session.'''

        self.feed_dict = {
            self.cam_holders[i]: self.cams[i]
            for i in range(len(self.cams))
        }

        self.feed_dict.update(
            (self.x_holders[i], self.x[i])
            for i in range(len(self.x))
        )

        self.feed_dict.update(
            (self.w_holders[i], self.w[i])
            for i in range(len(self.w))
        )

    def output(self):
        '''Returns calculation result.'''

        return BAOutput(self.reproj_error, self.w_err, self.jacobian)

    def calculate_objective(self, times):
        '''Calculates objective function many times.'''

        with tf.compat.v1.Session() as session:
            for _ in range(times):
                self.reproj_error, self.w_err = session.run(
                    (
                        self.reproj_err_operations,
                        self.w_err_operations
                    ),
                    feed_dict = self.feed_dict
                )

    def calculate_jacobian(self, times):
        ''' Calculates objective function jacobian many times.'''

        with tf.compat.v1.Session() as session:
            for _ in range(times):
                dr, dw = session.run(
                    (
                        self.r_err_grad_operations,
                        self.w_err_grad_operations
                    ),
                    feed_dict = self.feed_dict
                )

                for i in range(self.p):
                    self.jacobian.insert_reproj_err_block(
                        i,
                        self.obs[i, 0],
                        self.obs[i, 1],
                        dr[i]
                    )

                for i in range(self.p):
                    self.jacobian.insert_w_err_block(i, dw[i])