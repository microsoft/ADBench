import numpy as np
import freetensor as ft

from modules.FreeTensor.utils import to_ft_tensor, to_ft_tensors, ft_jacobian
from shared.ITest import ITest
from shared.GMMData import GMMInput, GMMOutput
from modules.FreeTensor.gmm_objective import gmm_objective_inline



class FreeTensorGPUGMM(ITest):
    '''Test class for GMM differentiation by FreeTensor.'''

    def prepare(self, input):
        '''Prepares calculating. This function must be run before
        any others.'''

        self.inputs = to_ft_tensors((input.alphas, input.means, input.icf))
        self.params = to_ft_tensors((input.x, input.wishart.gamma)) + (to_ft_tensor(input.wishart.m, "int32"),)

        self.d = input.means.shape[1]
        self.k = input.alphas.shape[0]
        self.n = input.x.shape[0]
        assert input.alphas.shape == (self.k,)
        assert input.means.shape == (self.k, self.d)
        assert input.icf.shape == (self.k, self.d * (self.d + 1) // 2)
        assert input.x.shape == (self.n, self.d)

        self.device = ft.GPU()
        with self.device:

            @ft.transform
            def gmm_objective(
                    alphas, means, icf, x, wishart_gamma, wishart_m,
                    d: ft.JIT[int],
                    k: ft.JIT[int],
                    n: ft.JIT[int]):
                alphas: ft.Var[(k,), "float64"]
                means: ft.Var[(k, d), "float64"]
                icf: ft.Var[(k, d * (d + 1) // 2), "float64"]
                x: ft.Var[(n, d), "float64"]
                wishart_gamma: ft.Var[(), "float64"]
                wishart_m: ft.Var[(), "int32"]
                return gmm_objective_inline(alphas, means, icf, x, wishart_gamma, wishart_m)

            self.comp_objective = ft.optimize(
                    gmm_objective,
                    schedule_callback=lambda s: s.auto_schedule(self.device))
            self.comp_jacobian = ft_jacobian(
                    gmm_objective, len(self.inputs),
                    schedule_callback=lambda s: s.auto_schedule(self.device))

    def output(self):
        '''Returns calculation result.'''

        return GMMOutput(self.objective.numpy().item(), self.gradient.numpy())

    def calculate_objective(self, times):
        '''Calculates objective function many times.'''

        for i in range(times):
            self.objective = self.comp_objective(*self.inputs, *self.params, self.d, self.k, self.n)

    def calculate_jacobian(self, times):
        '''Calculates objective function jacobian many times.'''

        for i in range(times):
            self.objective, self.gradient = self.comp_jacobian(
                self.inputs,
                self.params + (self.d, self.k, self.n)
            )
