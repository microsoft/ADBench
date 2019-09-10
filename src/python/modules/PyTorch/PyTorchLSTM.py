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
from LSTMData import LSTMInput, LSTMOutput
from lstm_objective import loss



class PyTorchLSTM(ITest):
    '''Test class for LSTM diferentiation by PyTorch.'''

    def prepare(self, input):
        '''Prepares calculating. This function must be run before
        any others.'''

        self.input = input
        self.result = LSTMOutput()

    def output(self):
        '''Returns calculation result.'''

        return self.result

    def calculate_objective(self, times):
        '''Calculates objective function many times.'''

        for i in range(times):
            self.result.objective = loss(
                self.input.main_params,
                self.input.extra_params,
                self.input.state,
                self.input.sequence
            )

    def calculate_jacobian(self, times):
        ''' Calculates objective function jacobian many times.'''

        for i in range(times):
            obj, grad = torch_func(
                loss,
                (
                    self.input.main_params,
                    self.input.extra_params
                ),
                (
                    self.input.state,
                    self.input.sequence
                ),
                True
            )

            self.result.objective = obj
            self.result.gradient = grad