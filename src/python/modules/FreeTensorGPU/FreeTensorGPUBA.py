import numpy as np
import freetensor as ft

from modules.FreeTensor.utils import to_ft_tensors, to_ft_tensor, ft_jacobian_inline
from shared.ITest import ITest
from shared.defs import BA_NCAMPARAMS
from shared.BAData import BAInput, BAOutput
from shared.BASparseMat import BASparseMat
from modules.FreeTensor.ba_objective import compute_reproj_err, compute_w_err



class FreeTensorGPUBA(ITest):
    '''Test class for BA diferentiation by FreeTensor.'''

    def prepare(self, input):
        '''Prepares calculating. This function must be run before
        any others.'''

        self.p = len(input.obs)
        self.cams = to_ft_tensor(input.cams)
        self.x = to_ft_tensor(input.x)
        self.w = to_ft_tensor(input.w)
        self.obs = to_ft_tensor(input.obs, dtype = 'int64')
        self.feats = to_ft_tensor(input.feats)

        self.device = ft.GPU()
        with self.device:

            @ft.optimize(schedule_callback=lambda s: s.auto_schedule(self.device))
            def comp_objective(
                    p: ft.JIT[int],
                    n: ft.JIT[int],
                    m: ft.JIT[int],
                    cams, x, w, obs, feats):
                cams: ft.Var[(n, BA_NCAMPARAMS), "float64"]
                x: ft.Var[(m, 3), "float64"]
                w: ft.Var[(p,), "float64"]
                obs: ft.Var[(p, 2), "int64"]
                feats: ft.Var[(p, 2), "float64"]

                reproj_error = ft.empty((2 * p,), "float64")
                w_err = ft.empty((p,), "float64")
                for j in range(self.p):
                    reproj_error[j * 2 : (j + 1) * 2] = compute_reproj_err(
                            cams[obs[j, 0]], x[obs[j, 1]], w[j], feats[j])
                    w_err[j] = compute_w_err(w[j])
                return reproj_error, w_err

            @ft.optimize(schedule_callback=lambda s: s.auto_schedule(self.device))
            def comp_jacobian(
                    p: ft.JIT[int],
                    n: ft.JIT[int],
                    m: ft.JIT[int],
                    cams, x, w, obs, feats):
                cams: ft.Var[(n, BA_NCAMPARAMS), "float64"]
                x: ft.Var[(m, 3), "float64"]
                w: ft.Var[(p,), "float64"]
                obs: ft.Var[(p, 2), "int64"]
                feats: ft.Var[(p, 2), "float64"]

                reproj_error = ft.empty((2 * p,), "float64")
                w_err = ft.empty((p,), "float64")
                J_reproj_error = ft.empty((p, 2 * (BA_NCAMPARAMS + 3 + 1)), "float64")
                J_w_err = ft.empty((p,), "float64")
                for j in range(self.p):
                    reproj_error[j * 2 : (j + 1) * 2], J_reproj_error[j] = ft_jacobian_inline(
                            compute_reproj_err,
                            (cams[obs[j, 0]], x[obs[j, 1]], w[j]),
                            (feats[j],))
                    w_err[j], J_w_err[j:j+1] = ft_jacobian_inline(
                            compute_w_err,
                            (w[j],))
                return reproj_error, w_err, J_reproj_error, J_w_err

        self.comp_objective = comp_objective
        self.comp_jacobian = comp_jacobian

        self.reproj_error = None
        self.w_err = None
        self.jacobian = BASparseMat(len(input.cams), len(input.x), self.p)

    def output(self):
        '''Returns calculation result.'''

        # Postprocess Jacobian into BASparseMat
        J_reproj_error = self.J_reproj_error.numpy()
        J_w_err = self.J_w_err.numpy()
        obs = self.obs.numpy()
        for j in range(self.p):
            camIdx = obs[j, 0]
            ptIdx = obs[j, 1]
            self.jacobian.insert_reproj_err_block(j, camIdx, ptIdx, J_reproj_error[j])
        for j in range(self.p):
            self.jacobian.insert_w_err_block(j, J_w_err[j])

        return BAOutput(
            self.reproj_error.numpy(),
            self.w_err.numpy(),
            self.jacobian
        )

    def calculate_objective(self, times):
        '''Calculates objective function many times.'''

        for i in range(times):
            self.reproj_error, self.w_err = self.comp_objective(
                    self.p, self.cams.shape[0], self.x.shape[0],
                    self.cams, self.x, self.w, self.obs, self.feats)
        self.device.sync()

    def calculate_jacobian(self, times):
        ''' Calculates objective function jacobian many times.'''

        for i in range(times):
            self.reproj_error, self.w_err, self.J_reproj_error, self.J_w_err = self.comp_jacobian(
                    self.p, self.cams.shape[0], self.x.shape[0],
                    self.cams, self.x, self.w, self.obs, self.feats)

        self.device.sync()
