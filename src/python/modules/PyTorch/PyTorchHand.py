# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import numpy as np
import torch

from modules.PyTorch.utils import to_torch_tensor, torch_jacobian
from shared.ITest import ITest
from shared.HandData import HandInput, HandOutput
from modules.PyTorch.hand_objective import hand_objective, \
                                           hand_objective_complicated



class PyTorchHand(ITest):
    '''Test class for hand tracking function.'''

    def prepare(self, input):
        '''Prepares calculating. This function must be run before
        any others.'''

        self.bone_count = input.data.model.bone_count
        nrows = 3 * len(input.data.correspondences)
        self.complicated = len(input.us) > 0

        if self.complicated:
            self.inputs = to_torch_tensor(
                np.append(input.us.flatten(), input.theta),
                grad_req = True
            )
            self.params = (
                self.bone_count,
                to_torch_tensor(input.data.model.parents, dtype = torch.int32),
                to_torch_tensor(input.data.model.base_relatives),
                to_torch_tensor(input.data.model.inverse_base_absolutes),
                to_torch_tensor(input.data.model.base_positions),
                to_torch_tensor(input.data.model.weights),
                input.data.model.is_mirrored,
                to_torch_tensor(input.data.points),
                to_torch_tensor(
                    input.data.correspondences,
                    dtype = torch.int32
                ),
                input.data.model.triangles
            )

            self.objective_function = hand_objective_complicated
            ncols = len(input.theta) + 2
        else:
            self.inputs = to_torch_tensor(
                input.theta,
                grad_req = True
            )

            self.params = (
                self.bone_count,
                to_torch_tensor(input.data.model.parents, dtype = torch.int32),
                to_torch_tensor(input.data.model.base_relatives),
                to_torch_tensor(input.data.model.inverse_base_absolutes),
                to_torch_tensor(input.data.model.base_positions),
                to_torch_tensor(input.data.model.weights),
                input.data.model.is_mirrored,
                to_torch_tensor(input.data.points),
                to_torch_tensor(input.data.correspondences, dtype = torch.int32)
            )

            self.objective_function = hand_objective
            ncols = len(input.theta)

        self.objective = torch.zeros(nrows)
        self.jacobian = torch.zeros([ nrows, ncols ])

    def output(self):
        '''Returns calculation result.'''

        return HandOutput(
            self.objective.detach().flatten().numpy(),
            self.jacobian.detach().numpy()
        )
    
    def calculate_objective(self, times):
        '''Calculates objective function many times.'''

        for i in range(times):
            self.objective = self.objective_function(
                self.inputs,
                *self.params
            )

    def calculate_jacobian(self, times):
        '''Calculates objective function jacobian many times.'''

        for i in range(times):
            self.objective, J = torch_jacobian(
                self.objective_function,
                ( self.inputs, ),
                self.params,
                False
            )

            if self.complicated:
                # getting us part of jacobian
                # Note: jacobian has the following structure:
                #
                #   [us_part theta_part]
                #
                # where in us part is a block diagonal matrix with blocks of
                # size [3, 2]
                n_rows, n_cols = J.shape
                us_J = torch.empty([ n_rows, 2 ])
                for i in range(n_rows // 3):
                    for k in range(3):
                        us_J[3 * i + k] = J[3 * i + k][2 * i: 2 * i + 2]

                us_count = 2 * n_rows // 3
                theta_count = n_cols - us_count
                theta_J = torch.empty([ n_rows, theta_count ])
                for i in range(n_rows):
                    theta_J[i] = J[i][us_count:]

                self.jacobian = torch.cat(( us_J, theta_J), 1)
            else:
                self.jacobian = J