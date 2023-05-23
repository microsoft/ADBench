import numpy as np
import freetensor as ft

from modules.FreeTensor.utils import to_ft_tensor, ft_jacobian
from shared.ITest import ITest
from shared.HandData import HandInput, HandOutput
from modules.FreeTensor.hand_objective import hand_objective, \
                                           hand_objective_complicated



class FreeTensorHand(ITest):
    '''Test class for hand tracking function.'''

    def prepare(self, input):
        '''Prepares calculating. This function must be run before
        any others.'''

        self.bone_count = input.data.model.bone_count
        nrows = 3 * len(input.data.correspondences)
        self.complicated = len(input.us) > 0

        bone_count = self.bone_count
        is_mirrored = input.data.model.is_mirrored

        if self.complicated:
            self.inputs = to_ft_tensor(np.append(input.us.flatten(), input.theta))
            self.params = (
                bone_count,
                to_ft_tensor(input.data.model.parents, dtype = "int32"),
                to_ft_tensor(input.data.model.base_relatives),
                to_ft_tensor(input.data.model.inverse_base_absolutes),
                to_ft_tensor(input.data.model.base_positions),
                to_ft_tensor(input.data.model.weights),
                is_mirrored,
                to_ft_tensor(input.data.points),
                to_ft_tensor(input.data.correspondences, dtype = "int32"),
                to_ft_tensor(input.data.model.triangles, dtype = "int32"),
                self.inputs.shape[0],
                input.data.model.parents.shape[0],
                input.data.model.base_positions.shape[0],
                input.data.points.shape[0],
                input.data.model.triangles.shape[0],
            )

            @ft.transform
            def comp_objective(
                params,
                nbones: ft.JIT[int],
                parents,
                base_relatives,
                inverse_base_absolutes,
                base_positions,
                weights,
                mirror_factor: ft.JIT[bool],
                points,
                correspondences,
                triangles,
                nparam: ft.JIT[int],
                nparent: ft.JIT[int],
                nvert: ft.JIT[int],
                npoint: ft.JIT[int],
                ntriangle: ft.JIT[int],
            ):
                params: ft.Var[(nparam,), "float64"]
                parents: ft.Var[(nparent,), "int32"]
                base_relatives: ft.Var[(nparent, 4, 4), "float64"]
                inverse_base_absolutes: ft.Var[(nparent, 4, 4), "float64"]
                base_positions: ft.Var[(nvert, 4), "float64"]
                weights: ft.Var[(nvert, nbones), "float64"]
                points: ft.Var[(npoint, 3), "float64"]
                correspondences: ft.Var[(npoint,), "int32"]
                triangles: ft.Var[(ntriangle, 3), "int32"]
                return hand_objective_complicated(
                    params,
                    nbones,
                    parents,
                    base_relatives,
                    inverse_base_absolutes,
                    base_positions,
                    weights,
                    mirror_factor,
                    points,
                    correspondences,
                    triangles)

        else:
            self.inputs = to_ft_tensor(input.theta)
            self.params = (
                bone_count,
                to_ft_tensor(input.data.model.parents, dtype = "int32"),
                to_ft_tensor(input.data.model.base_relatives),
                to_ft_tensor(input.data.model.inverse_base_absolutes),
                to_ft_tensor(input.data.model.base_positions),
                to_ft_tensor(input.data.model.weights),
                is_mirrored,
                to_ft_tensor(input.data.points),
                to_ft_tensor(input.data.correspondences, dtype = "int32"),
                self.inputs.shape[0],
                input.data.model.parents.shape[0],
                input.data.model.base_positions.shape[0],
                input.data.points.shape[0],
            )

            @ft.transform
            def comp_objective(
                params,
                nbones: ft.JIT[int],
                parents,
                base_relatives,
                inverse_base_absolutes,
                base_positions,
                weights,
                mirror_factor: ft.JIT[bool],
                points,
                correspondences,
                nparam: ft.JIT[int],
                nparent: ft.JIT[int],
                nvert: ft.JIT[int],
                npoint: ft.JIT[int],
            ):
                params: ft.Var[(nparam,), "float64"]
                parents: ft.Var[(nparent,), "int32"]
                base_relatives: ft.Var[(nparent, 4, 4), "float64"]
                inverse_base_absolutes: ft.Var[(nparent, 4, 4), "float64"]
                base_positions: ft.Var[(nvert, 4), "float64"]
                weights: ft.Var[(nvert, nbones), "float64"]
                points: ft.Var[(npoint, 3), "float64"]
                correspondences: ft.Var[(npoint,), "int32"]
                return hand_objective(
                    params,
                    nbones,
                    parents,
                    base_relatives,
                    inverse_base_absolutes,
                    base_positions,
                    weights,
                    mirror_factor,
                    points,
                    correspondences)

        self.comp_objective = ft.optimize(
                comp_objective,
                schedule_callback=lambda s: s.auto_schedule(ft.CPU()))
        self.comp_jacobian = ft_jacobian(
                comp_objective, 1, False,
                schedule_callback=lambda s: s.auto_schedule(ft.CPU()))

        if self.complicated:

            @ft.optimize(schedule_callback=lambda s: s.auto_schedule(ft.CPU()))
            def post_jacobian(n_rows: ft.JIT[int], n_cols: ft.JIT[int], J):
                J: ft.Var[(n_rows, n_cols), "float64"]

                # getting us part of jacobian
                # Note: jacobian has the following structure:
                #
                #   [us_part theta_part]
                #
                # where in us part is a block diagonal matrix with blocks of
                # size [3, 2]
                us_J = ft.empty([ n_rows, 2 ], "float64")
                for i in range(n_rows // 3):
                    for k in range(3):
                        us_J[3 * i + k] = J[3 * i + k][2 * i: 2 * i + 2]

                us_count = 2 * n_rows // 3
                theta_count = n_cols - us_count
                theta_J = ft.empty([ n_rows, theta_count ], "float64")
                for i in range(n_rows):
                    theta_J[i] = J[i][us_count:]

                return ft.concat(( us_J, theta_J), 1)

            self.post_jacobian = post_jacobian


    def output(self):
        '''Returns calculation result.'''

        return HandOutput(
            self.objective.numpy().flatten(),
            self.jacobian.numpy()
        )

    def calculate_objective(self, times):
        '''Calculates objective function many times.'''

        for i in range(times):
            self.objective = self.comp_objective(
                self.inputs,
                *self.params,
            )

    def calculate_jacobian(self, times):
        '''Calculates objective function jacobian many times.'''

        for i in range(times):
            self.objective, J = self.comp_jacobian(
                ( self.inputs, ),
                self.params,
            )

            if self.complicated:
                self.jacobian = self.post_jacobian(J.shape[0], J.shape[1], J)
            else:
                self.jacobian = J
