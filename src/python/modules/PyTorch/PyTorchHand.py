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
from HandData import HandInput, HandOutput
from hand_objective import hand_objective, hand_objective_complicated



class PyTorchHand(ITest):
    '''Test class for hand tracking function.'''

    def prepare(self, input):
        '''Prepares calculating. This function must be run before
        any others.'''

        self.input = input
        self.result = HandData()
    
    def calculate_objective(self, times):
        '''Calculates objective function many times.'''

        if len(self.input.us) > 0:      # complicated
            for i in range(times):
                self.result.objective = hand_objective_complicated(
                    self.input.data.params,
                    self.input.data.nbones,
                    self.input.data.base_relatives,
                    self.input.data.parents,
                    self.input.data.inverse_base_absolutes,
                    self.input.data.base_positions,
                    self.input.weights,
                    self.input.mirror_factor,
                    self.input.points,
                    self.input.correspondences,
                    self.input.triangles
                )
        else:
            for i in range(times):
                self.result.objective = hand_objective(
                    self.input.data.params,
                    self.input.data.nbones,
                    self.input.data.base_relatives,
                    self.input.data.parents,
                    self.input.data.inverse_base_absolutes,
                    self.input.data.base_positions,
                    self.input.weights,
                    self.input.mirror_factor,
                    self.input.points,
                    self.input.correspondences
                )

    def calculate_jacobian(self, times):
        '''Calculates objective function jacobian many times.'''

        if len(self.input.us) > 0:      # complicated
            for i in range(times):
                pass
        else:
            for i in range(times):
                pass