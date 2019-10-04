from __future__ import absolute_import, division, print_function, \
                       unicode_literals
                       
import tensorflow as tf

from modules.Tensorflow.utils import to_tf_tensor
from shared.ITest import ITest
from shared.GMMData import GMMInput, GMMOutput
from modules.Tensorflow.gmm_objective import gmm_objective



class TensorflowGMM(ITest):
    '''Test class for GMM differentiation by Tensorflow.'''

    def prepare(self, input):
        '''Prepares calculating. This function must be run before
        any others.'''

        self.alphas = to_tf_tensor(input.alphas)
        self.means = to_tf_tensor(input.means)
        self.icf = to_tf_tensor(input.icf)

        self.x = to_tf_tensor(input.x)
        self.wishart_gamma = to_tf_tensor(input.wishart.gamma)
        self.wishart_m = to_tf_tensor(input.wishart.m)

        self.objective = tf.zeros(1)
        self.gradient = tf.zeros(0)

    def output(self):
        '''Returns calculation result.'''

        return GMMOutput(self.objective.numpy(), self.gradient.numpy())

    def calculate_objective(self, times):
        '''Calculates objective function many times.'''

        for _ in range(times):
            self.objective = gmm_objective(
                self.alphas,
                self.means,
                self.icf,
                self.x,
                self.wishart_gamma,
                self.wishart_m
            )


    def calculate_jacobian(self, times):
        '''Calculates objective function jacobian many times.'''

        for _ in range(times):
            with tf.GradientTape(persistent = True) as t:
                t.watch(self.alphas)
                t.watch(self.means)
                t.watch(self.icf)

                self.objective = gmm_objective(
                self.alphas,
                self.means,
                self.icf,
                self.x,
                self.wishart_gamma,
                self.wishart_m
            )

            dalphas = t.gradient(self.objective, self.alphas)
            dmeans = t.gradient(self.objective, self.means)
            dicf = t.gradient(self.objective, self.icf)
            self.gradient = tf.concat((
                tf.reshape(dalphas, [-1]),
                tf.reshape(dmeans, [-1]),
                tf.reshape(dicf, [-1])
            ), 0)