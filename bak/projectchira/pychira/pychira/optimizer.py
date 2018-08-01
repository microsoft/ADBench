import numpy as np
import util
util.add_boost_python_to_dll_path()
import pychira.fitsubdiv
import pychira.poseinfer

class Optimizer(object):
    def __init__(self, model_path, py_model):
        self.py_model = py_model
        self.pose_params_obj = pychira.poseinfer.PoseParams(py_model.n_bones)
        self.fitsubdiv_model = pychira.fitsubdiv.Model(model_path, True)
        self.options = pychira.fitsubdiv.Options()
        self.options.n_iterations = 25
        self.options.throttle_model_fitting_to_ms = 5000
        self.options.lambda_temporal_prior_ = 0.0
        self.options.lambda_beta_prior_ = 4.0
        self.sampled_coords = pychira.fitsubdiv.SampledCoordinatesSet(self.options, self.fitsubdiv_model)
        self.callbacks = []
        self.marker_map = {}
        for i, m in enumerate(py_model.markers):
            self.marker_map[m[0]] = i
        
    def add_callback(self, callback_function):
        self.callbacks.append(callback_function)

    def optimizer_callback(self, time_in_ms, energy, theta, surface_coordinates):
        pose_params_obj = self.fitsubdiv_model.get_pose_params(theta)
        pose_params_dict = {}
        pychira.poseinfer.update_pose_dict_from_obj(self.py_model, pose_params_dict, pose_params_obj)
        for f in self.callbacks:
            f(time_in_ms, energy, pose_params_dict, surface_coordinates)

    def optimize(self, pose_params_dict, data_points, data_normals, marker_dict=None):
        data_point_vector = pychira.fitsubdiv.VectorList(data_points.astype(np.float64))
        data_normal_vector = pychira.fitsubdiv.VectorList(data_normals.astype(np.float64))
        energy = pychira.fitsubdiv.Energy(self.fitsubdiv_model, data_point_vector, data_normal_vector, self.options)

        if marker_dict is not None:
            for name, known_pos in marker_dict.iteritems():
                model_pos = pychira.fitsubdiv.ModelPosition()
                vertices = self.py_model.markers[self.marker_map[name]][1]
                for v in vertices:
                    vert = pychira.fitsubdiv.WeightedVertex()
                    vert.vertex_id = v
                    vert.weight = 1.0 / len(vertices)
                    model_pos.vertices.append(vert)
                energy.add_known_correspondence(model_pos, known_pos.astype(np.float32))

        optimizer = pychira.fitsubdiv.Optimizer(self.options, self.fitsubdiv_model, energy, self.sampled_coords)
        self.state = energy.make_state()
        pychira.poseinfer.update_pose_obj_from_dict(self.py_model, pose_params_dict, self.pose_params_obj)
        self.state.thetas[0] = self.fitsubdiv_model.get_theta(self.pose_params_obj)
        result = optimizer.optimize(self.state, self.optimizer_callback)
        pychira.poseinfer.update_pose_dict_from_obj(self.py_model, pose_params_dict,
                                                    self.fitsubdiv_model.get_pose_params(self.state.thetas[0]))
        return result.final_energy
