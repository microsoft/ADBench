# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import numpy as np
import torch

from modules.PyTorchVmap.utils import to_torch_tensors, to_torch_tensor, \
                                  torch_jacobian
from shared.ITest import ITest
from shared.BAData import BAInput, BAOutput
from shared.BASparseMat import BASparseMat
from shared.defs import BA_NCAMPARAMS
from modules.PyTorchVmap.ba_objective import compute_reproj_err, compute_w_err


def jac_reproj_err(cam, x, w, feat):
    return torch_jacobian(compute_reproj_err, (cam, x, w), (feat, ))


batched_reproj_err = torch.vmap(compute_reproj_err)
batched_jac_reproj_err = torch.vmap(jac_reproj_err)


def jac_w_err(w):
    return torch_jacobian(compute_w_err, (w, ))


batched_w_err = torch.vmap(compute_w_err)
batched_jac_w_err = torch.vmap(jac_w_err)


class PyTorchVmapGPUBA(ITest):
    '''Test class for BA diferentiation by PyTorchGPU.'''

    def prepare(self, input):
        '''Prepares calculating. This function must be run before
        any others.'''

        self.p = len(input.obs)

        # we use tuple of tensors instead of multidimensional tensor
        # because torch doesn't differentiate by non-leaf tensors
        self.cams = to_torch_tensor(input.cams, grad_req=True, device='cuda')
        self.x = to_torch_tensor(input.x, grad_req=True, device='cuda')
        self.w = to_torch_tensor(input.w, grad_req=True, device='cuda')

        self.obs = to_torch_tensor(input.obs, dtype=torch.int64, device='cuda')
        self.feats = to_torch_tensor(input.feats, device='cuda')

        self.reproj_error = torch.zeros(2 * self.p,
                                        dtype=torch.float64,
                                        device='cuda')
        self.w_err = torch.zeros(len(input.w), device='cuda')
        self.jacobian = BASparseMat(len(input.cams), len(input.x), self.p)

    def output(self):
        '''Returns calculation result.'''

        # Postprocess Jacobian into BASparseMat
        J_reproj_error = self.J_reproj_error.detach().cpu().numpy()
        J_w_err = self.J_w_err.detach().cpu().numpy()
        obs = self.obs.detach().cpu().numpy()
        for j in range(self.p):
            camIdx = obs[j, 0]
            ptIdx = obs[j, 1]
            self.jacobian.insert_reproj_err_block(j, camIdx, ptIdx,
                                                  J_reproj_error[j])
        for j in range(self.p):
            self.jacobian.insert_w_err_block(j, J_w_err[j])

        return BAOutput(self.reproj_error.detach().cpu().numpy(),
                        self.w_err.detach().cpu().numpy(), self.jacobian)

    def calculate_objective(self, times):
        '''Calculates objective function many times.'''

        for i in range(times):
            self.reproj_error = batched_reproj_err(
                torch.index_select(self.cams, 0, self.obs[:, 0]),
                torch.index_select(self.x, 0, self.obs[:, 1]),
                self.w,
                self.feats,
            )
            self.w_err = batched_w_err(self.w)

            assert self.reproj_error.shape == (self.p, 2)
            assert self.w_err.shape == (self.p, )

            self.reproj_error = self.reproj_error.flatten()
        torch.cuda.synchronize()

    def calculate_jacobian(self, times):
        ''' Calculates objective function jacobian many times.'''

        for i in range(times):
            self.reproj_error, self.J_reproj_error = batched_jac_reproj_err(
                torch.index_select(self.cams, 0, self.obs[:, 0]),
                torch.index_select(self.x, 0, self.obs[:, 1]),
                self.w,
                self.feats,
            )
            self.w_err, self.J_w_err = batched_jac_w_err(self.w)

            assert self.reproj_error.shape == (self.p, 2)
            assert self.w_err.shape == (self.p, )

            assert self.J_reproj_error.shape == (self.p,
                                                 2 * (BA_NCAMPARAMS + 3 + 1))
            assert self.J_w_err.shape == (self.p, 1)

            self.reproj_error = self.reproj_error.flatten()
            self.J_w_err = self.J_w_err.flatten()
        torch.cuda.synchronize()
