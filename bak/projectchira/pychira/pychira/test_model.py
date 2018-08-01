import os
import numpy as np
import unittest
import util
util.add_boost_python_to_dll_path()
import poseinfer
from model import load_model

class TestModelBase(object):
    def setUp(self):
        # Set up the objects needed to skin a poseinfer model
        self.pi_model = poseinfer.Model(self.model_path)
        self.pi_pose_params = poseinfer.PoseParams(22)
        
        # And those needed to skin a python model
        self.py_model = load_model(self.model_path)

    def assertNearlyEqual(self, a, b, tol, msg=None):
        max_diff = np.amax(np.abs(a - b))
        self.assertTrue(max_diff < tol, 'Not nearly equal : max error %8f' % max_diff +
                                        (' for ' + msg if msg is not None else ''))

    def check_skinned_vertex_positions(self):
        # Get skinned vertices for Python model
        py_pose_params = {}
        poseinfer.update_pose_dict_from_obj(self.py_model, py_pose_params, self.pi_pose_params)
        py_vertices = self.py_model.get_skinned_vertex_positions(py_pose_params)

        # Set up skinning for poseinfer model
        pi_shape = np.zeros(poseinfer.Vertex.Bases, np.float32)
        pi_shape[0] = 1.0
        pi_pose = self.pi_model.skeleton().bind_to_world_transforms(self.pi_pose_params, pi_shape)
        pi_vertices = self.pi_model.vertices()

        # Same number of vertices
        self.assertEqual(py_vertices.shape[0], len(pi_vertices))
        # Check each vertex
        for i, pi_vert in enumerate(pi_vertices):
            pi_pos = pi_vert.skinned_position(pi_pose, pi_shape)
            py_pos = py_vertices[i, :]
            self.assertNearlyEqual(pi_pos, py_pos, self.equality_tol, 'vertex ' + str(i))

    def test_neutral(self):
        self.check_skinned_vertex_positions()

    def test_global(self):
        self.pi_pose_params.global_scale = np.random.rand(3).astype(np.float32)
        self.pi_pose_params.global_rotation = np.random.rand(3).astype(np.float32)
        self.pi_pose_params.global_translation = np.random.rand(3).astype(np.float32)
        self.check_skinned_vertex_positions()

    def test_forearm(self):
        forearm_joint = 21
        self.assertEqual(self.py_model.names[forearm_joint], "forearm")
        flexabduct = np.zeros(3, np.float32)
        flexabduct[0:2] = np.random.rand(2)
        self.pi_pose_params.set_joint_rotation(forearm_joint, flexabduct)
        self.check_skinned_vertex_positions()

    def test_random_pose(self):
        self.pi_pose_params.global_scale = np.random.rand(3).astype(np.float32)
        self.pi_pose_params.global_rotation = np.random.rand(3).astype(np.float32)
        self.pi_pose_params.global_translation = np.random.rand(3).astype(np.float32)
        for i in xrange(22):
            self.pi_pose_params.set_joint_rotation(i, np.random.rand(3).astype(np.float32))
        self.check_skinned_vertex_positions()

class TestV3BlenderModel(TestModelBase, unittest.TestCase):
    equality_tol = 1e-6
    model_path = os.path.join(util.get_chira_root(), 'data/models/hand-model-v3/exported_template_from_blender')

# class Test5BasesModel(TestModelBase, unittest.TestCase):
#     model_path = os.path.join(util.get_chira_root(), 'data/models/hand-model-v3/exported_template_from_blender-5_bases')

if __name__ == '__main__':
    np.random.seed(31337)
    unittest.main(verbosity=2)
