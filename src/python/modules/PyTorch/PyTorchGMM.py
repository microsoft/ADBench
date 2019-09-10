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

from torch_wrapper import torch_func
from ITest import ITest
from GMMData import GMMInput, GMMOutput
from gmm_objective import gmm_objective



class PyTorchGMM(ITest):
    '''Test class for GMM differentiation by PyTorch.'''

    def prepare(self, input):
        '''Prepares calculating. This function must be run before
        any others.'''

        self.input = input
        self.result = GMMOutput()

    def output(self):
        '''Returns calculation result.'''

        return self.result

    def calculate_objective(self, times):
        '''Calculates objective function many times.'''

        for i in range(times):
            self.output.objective = gmm_objective(
                self.input.alphas,
                self.input.means,
                self.input.isf,
                self.input.x,
                self.input.wishart.gamma,
                self.input.widhart.m
            )
    
    def calculate_jacobian(self, times):
        '''Calculates objective function jacobian many times.'''

        for i in range(times):
            obj, grad = torch_func(
                gmm_objective,
                (
                    self.input.alphas,
                    self.input.means,
                    self.input.icf
                ),
                (
                    self.input.x,
                    self.input.wishart.gamma,
                    self.input.widhart.m
                ),
                True
            )

            self.result.objective = obj
            self.result.gradient = grad