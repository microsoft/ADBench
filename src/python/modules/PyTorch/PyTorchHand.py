import sys
from os import path

# adding folder with files for importing
sys.path.append(
    path.join(
        path.abspath(path.dirname(__file__)),
        "..",
        "..",
        "shared"
    )
)

import numpy as np
import torch

from modules.PyTorch.utils import to_torch_tensor, torch_jacobian
from shared.ITest import ITest
from shared.HandData import HandInput, HandOutput
from modules.PyTorch.hand_objective import hand_objective, hand_objective_complicated



class PyTorchHand(ITest):
    '''Test class for hand tracking function.'''

    @classmethod
    def prepare(self, input):
        '''Prepares calculating. This function must be run before
        any others.'''

        self.bone_count = input.data.model.bone_count
        self.nrows = 3 * len(input.data.correspondences)
        self.complicated = len(input.us) > 0

        if self.complicated:
            self.inputs =to_torch_tensor(
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
                to_torch_tensor(input.data.correspondences, dtype = torch.int32),
                input.data.model.triangles
            )

            self.objective_function = hand_objective_complicated
            self.ncols = len(input.theta) + 2
            self.us_count = len(input.us)
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
            self.ncols = len(input.theta)

        self.objective = torch.zeros(self.nrows)
        self.jacobian = torch.zeros(self.nrows * self.ncols)

    @classmethod
    def output(self):
        '''Returns calculation result.'''

        return HandOutput(
            self.objective.detach().flatten().numpy(),
            self.jacobian.detach().numpy()
        )
    
    @classmethod
    def calculate_objective(self, times):
        '''Calculates objective function many times.'''

        for i in range(times):
            self.objective = self.objective_function(
                self.inputs,
                *self.params
            )

    @classmethod
    def calculate_jacobian(self, times):
        '''Calculates objective function jacobian many times.'''

        for i in range(times):
            self.objective, J = torch_jacobian(
                self.objective_function,
                ( self.inputs, ),
                self.params
            )

            if self.complicated:
                start = (self.ncols - 2) * self.nrows
                finish = self.nrows * (2 * self.us_count + self.ncols - 2)
                step = 2 * self.nrows + 3

                us_J = [
                    torch.cat((
                        J[i:i + 3],
                        J[i + self.nrows:i + self.nrows + 3]
                    ))
                    for i in range(start, finish, step)
                ]

                us_J = torch.cat(us_J)
                self.jacobian = torch.cat((
                    J[:self.nrows * (self.ncols - 2)],
                    us_J
                ))
            else:
                self.jacobian = J