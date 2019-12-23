# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

from __future__ import absolute_import, division, print_function, \
                       unicode_literals

import tensorflow as tf

from modules.TensorflowCommon.utils import to_tf_tensor, flatten
from shared.ITest import ITest
from shared.BAData import BAInput, BAOutput
from shared.BASparseMat import BASparseMat
from modules.TensorflowCommon.ba_objective import compute_reproj_err, compute_w_err



class TensorflowBA(ITest):
    '''Test class for BA diferentiation by Tensorflow using eager execution.'''

    def prepare(self, input):
        '''Prepares calculating. This function must be run before
        any others.'''

        self.p = len(input.obs)

        self.cams = tuple(to_tf_tensor(cam) for cam in input.cams)
        self.x = tuple(to_tf_tensor(x) for x in input.x)
        self.w = tuple(to_tf_tensor(w) for w in input.w)

        self.obs = to_tf_tensor(input.obs, dtype = tf.int64)
        self.feats = to_tf_tensor(input.feats)

        self.reproj_error = tf.zeros(2 * self.p, dtype = tf.float64)
        self.w_err = tf.zeros(len(input.w))
        self.jacobian = BASparseMat(len(input.cams), len(input.x), self.p)

    def output(self):
        '''Returns calculation result.'''

        return BAOutput(
            self.reproj_error.numpy(),
            self.w_err.numpy(),
            self.jacobian
        )

    def calculate_objective(self, times):
        '''Calculates objective function many times.'''

        for _ in range(times):
            reproj = []
            w_err = []
            for j in range(self.p):
                reproj_err = compute_reproj_err(
                    self.cams[self.obs[j, 0]],
                    self.x[self.obs[j, 1]],
                    self.w[j],
                    self.feats[j]
                )

                reproj.append(reproj_err)

                w_err.append(compute_w_err(self.w[j]))

            self.reproj_error = tf.concat(reproj, 0)
            self.w_err = tf.stack(w_err, 0)

    def calculate_jacobian(self, times):
        ''' Calculates objective function jacobian many times.'''

        for _ in range(times):
            # reprojection error processing
            reproj_err = []
            for j in range(self.p):
                camIdx = self.obs[j, 0]
                ptIdx = self.obs[j, 1]

                with tf.GradientTape(persistent = True) as t:
                    t.watch(self.cams[camIdx])
                    t.watch(self.x[ptIdx])
                    t.watch(self.w[j])

                    rej = compute_reproj_err(
                        self.cams[camIdx],
                        self.x[ptIdx],
                        self.w[j],
                        self.feats[j]
                    )

                reproj_err.append(rej)
                dc, dx, dw = t.jacobian(
                    rej,
                    (self.cams[camIdx], self.x[ptIdx], self.w[j]),
                    experimental_use_pfor = False
                )

                J = tf.concat(
                    ( dc, dx, tf.reshape(dw, [2, 1]) ),
                    axis = 1
                )

                J = flatten(J, column_major = True).numpy()
                self.jacobian.insert_reproj_err_block(j, camIdx, ptIdx, J)

            self.reproj_error = tf.concat(reproj_err, 0)

            # weight error processing
            w_err = []
            for j in range(self.p):
                with tf.GradientTape(persistent = True) as t:
                    t.watch(self.w[j])
                    wj = compute_w_err(self.w[j])

                w_err.append(wj)
                dwj = t.gradient(wj, self.w[j])
                self.jacobian.insert_w_err_block(j, dwj.numpy())

            self.w_err = tf.stack(w_err, 0)