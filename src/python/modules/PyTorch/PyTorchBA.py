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
from BAData import BAInput, BAOutput
from ba_objective import ba_objective



class PyTorchBA(ITest):
    '''Test class for BA diferentiation by PyTorch.'''

    def prepare(self, input):
        '''Prepares calculating. This function must be run before
        any others.'''

        self.input = input
        self.result = BAOutput()

    def output(self):
        '''Returns calculation result.'''

        return self.result

    def calculate_objective(self, times):
        '''Calculates objective function many times.'''

        for i in range(times):
            res = ba_objective(
                self.input.cam,
                self.input.X,
                self.input.w,
                self.input.obs,
                self.input.feats
            )

            self.result.reproj_err = res[0]
            self.result.w_err = res[1]

    def calculate_jacobian(self, times):
        ''' Calculates objective function jacobian many times.'''

        for i in range(times):
            pass