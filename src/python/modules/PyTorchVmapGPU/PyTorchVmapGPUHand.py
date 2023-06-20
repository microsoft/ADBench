# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import numpy as np
import torch

from modules.PyTorchVmap.utils import to_torch_tensor, torch_jacobian
from shared.ITest import ITest
from shared.HandData import HandInput, HandOutput
from modules.PyTorchVmap.hand_objective import (hand_objective,
                                                hand_objective_complicated,
                                                hand_objective_complicated_d)


class PyTorchVmapGPUHand(ITest):
    '''Test class for hand tracking function.'''

    def prepare(self, input):
        '''Prepares calculating. This function must be run before
        any others.'''

        self.bone_count = input.data.model.bone_count
        nrows = 3 * len(input.data.correspondences)
        self.complicated = len(input.us) > 0

        # Work around a PyTorch issue: https://github.com/pytorch/pytorch/issues/99405
        bone_count = torch.tensor(self.bone_count, device='cuda')
        is_mirrored = torch.tensor(input.data.model.is_mirrored, device='cuda')

        if self.complicated:
            self.inputs = to_torch_tensor(np.append(input.us.flatten(),
                                                    input.theta),
                                          grad_req=True,
                                          device='cuda')
            self.params = (bone_count,
                           to_torch_tensor(input.data.model.parents,
                                           dtype=torch.int32,
                                           device='cuda'),
                           to_torch_tensor(input.data.model.base_relatives,
                                           device='cuda'),
                           to_torch_tensor(
                               input.data.model.inverse_base_absolutes,
                               device='cuda'),
                           to_torch_tensor(input.data.model.base_positions,
                                           device='cuda'),
                           to_torch_tensor(input.data.model.weights,
                                           device='cuda'), is_mirrored,
                           to_torch_tensor(input.data.points, device='cuda'),
                           to_torch_tensor(input.data.correspondences,
                                           dtype=torch.int32,
                                           device='cuda'),
                           to_torch_tensor(input.data.model.triangles,
                                           device='cuda'))

            self.objective_function = hand_objective_complicated
            ncols = len(input.theta) + 2
        else:
            self.inputs = to_torch_tensor(input.theta,
                                          grad_req=True,
                                          device='cuda')

            self.params = (bone_count,
                           to_torch_tensor(input.data.model.parents,
                                           dtype=torch.int32,
                                           device='cuda'),
                           to_torch_tensor(input.data.model.base_relatives,
                                           device='cuda'),
                           to_torch_tensor(
                               input.data.model.inverse_base_absolutes,
                               device='cuda'),
                           to_torch_tensor(input.data.model.base_positions,
                                           device='cuda'),
                           to_torch_tensor(input.data.model.weights,
                                           device='cuda'), is_mirrored,
                           to_torch_tensor(input.data.points, device='cuda'),
                           to_torch_tensor(input.data.correspondences,
                                           dtype=torch.int32,
                                           device='cuda'))

            self.objective_function = hand_objective
            ncols = len(input.theta)

        self.objective = torch.zeros(nrows, device='cuda')
        self.jacobian = torch.zeros([nrows, ncols], device='cuda')

    def output(self):
        '''Returns calculation result.'''

        return HandOutput(self.objective.detach().flatten().cpu().numpy(),
                          self.jacobian.detach().cpu().numpy())

    def calculate_objective(self, times):
        '''Calculates objective function many times.'''

        for i in range(times):
            self.objective = self.objective_function(self.inputs, *self.params)
        torch.cuda.synchronize()

    def calculate_jacobian(self, times):
        '''Calculates objective function jacobian many times.'''

        for i in range(times):
            if not self.complicated:
                self.objective, self.jacobian = torch_jacobian(
                    self.objective_function, (self.inputs, ), self.params,
                    False)
            else:
                self.objective, self.jacobian = hand_objective_complicated_d(
                    self.inputs,
                    *self.params,
                )
        torch.cuda.synchronize()
