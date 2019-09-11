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

from utils import to_torch_tensors, to_torch_tensor, torch_jacobian
from ITest import ITest
from BAData import BAInput, BAOutput
from BASparseMat import BASparseMat
from ba_objective import ba_objective_part



class PyTorchBA(ITest):
    '''Test class for BA diferentiation by PyTorch.'''

    def prepare(self, input):
        '''Prepares calculating. This function must be run before
        any others.'''

        self.p = len(input.obs)
        self.inputs = to_torch_tensors(
            (input.cams, input.x, input.w),
            grad_req = True
        )

        self.params = (
            to_torch_tensor(input.obs, dtype = torch.int64),
            to_torch_tensor(input.feats)
        )

        self.reproj_error = torch.zeros(2 * self.p, dtype = torch.float64)
        self.w_err = torch.zeros(len(input.w))
        self.jacobian = BASparseMat()

    def output(self):
        '''Returns calculation result.'''

        return BAOutput(
            self.reproj_error.detach().numpy(),
            self.w_err.detach().numpy(),
            self.jacobian
        )

    def calculate_objective(self, times):
        '''Calculates objective function many times.'''

        reproj_error = torch.empty((self.p, 2), dtype = torch.float64)
        for i in range(times):
            for j in range(self.p):
                reproj_error[j], self.w_err[j] = ba_objective_part(
                    *self.inputs,
                    *self.params,
                    j
                )

            self.reproj_error = reproj_error.flatten()

    def calculate_jacobian(self, times):
        ''' Calculates objective function jacobian many times.'''

        reproj_error = torch.empty((self.p, 2), dtype = torch.float64)
        for i in range(times):
            for j in range(self.p):
                res, J = torch_jacobian(
                    ba_objective_part,
                    self.inputs,
                    self.params + (j, )
                )

                reproj_error[j] = res[0]
                self.w_err[j] = res[1]
                self.jacobian.insert_reproj_err_block(J[0])
                self.jacobian.insert_w_err_block(J[1])

            self.reproj_error = reproj_error.flatten()