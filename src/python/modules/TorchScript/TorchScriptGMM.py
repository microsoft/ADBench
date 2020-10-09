# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

from __future__ import annotations

import numpy as np
import torch

from modules.PyTorch.utils import to_torch_tensors, torch_jacobian
from shared.ITest import ITest
from shared.GMMData import GMMInput, GMMOutput
from modules.TorchScript.gmm_objective import gmm_objective

# TorchScript doesn't currently support * argument unpacking so make an explicit set of arguments.
@torch.jit.script
def calculate_objective_ts(times:int, alphas, means, icf, x, wishart_gamma, wishart_m):
    
    objective = torch.empty(0, 0)
    for i in range(times):
        objective = gmm_objective(alphas, means, icf, x, wishart_gamma, wishart_m)
    return objective

class TorchScriptGMM(ITest):
    '''Test class for GMM differentiation by TorchScript.'''

    def prepare(self, input):
        '''Prepares calculating. This function must be run before
        any others.'''

        self.inputs = to_torch_tensors(
            (input.alphas, input.means, input.icf),
            grad_req = True
        )

        self.params = to_torch_tensors(
            (input.x, input.wishart.gamma, input.wishart.m)
        )

        self.objective = torch.zeros(1)
        self.gradient = torch.empty(0)

    def output(self):
        '''Returns calculation result.'''

        return GMMOutput(self.objective.item(), self.gradient.numpy())

    def calculate_objective(self, times:int):
        '''Calculates objective function many times.'''

        self.objective = calculate_objective_ts(times, *self.inputs, *self.params)

        #for i in range(times):
            # Tried to access nonexistent attribute or method 'inputs' of type 'Tensor (inferred)'.:
            #self.objective = gmm_objective(*self.inputs, *self.params)
            

    def calculate_jacobian(self, times:int):
        '''Calculates objective function jacobian many times.'''

        for i in range(times):
            self.objective, self.gradient = torch_jacobian(
                gmm_objective,
                self.inputs,
                self.params
            )