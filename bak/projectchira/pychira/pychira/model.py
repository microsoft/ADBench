"""A class implementing our LBS Hand Model."""

import os
from rotation import *

PATH = os.path.dirname(os.path.abspath(__file__))

HAND_MODEL_V3_PATH, HAND_MODEL_V4_PATH = [os.path.join(PATH, '../../../../data/models/%s/exported_template_from_blender/' % dir_name) for dir_name in ['hand-model-v3', 'hand-model-v4']]

DELIM=':'
import numpy as np

# Set this to either axis_angle or a list of three letters indicating the Euler axes
# that correspond to the rotation parameters

# Z is abduction.
# X is flexion.

ROTATIONAL_PARAMETERIZATION = 'xzy' # Flexion, Abduction, Twist

# If ROTATIONAL_PARAMETERIZATION is a list of Euler angles, we need to know the application order here
# (e.g. 'xyz' is a Rx * Ry * Rz)

EULER_ANGLE_APPLICATION = 'zyx' # Must match the order given by poseinfer::pose_params::joint

class Model(object):

    def __init__(self, parents, base_relatives, triangles, base_positions, base_normals, weights, names=None):
        np.set_printoptions(suppress=True)

        # Sanity checks.
        assert len(parents) == len(base_relatives)
        self.n_bones = len(parents)

        self.n_vertices = base_positions.shape[0]
        self.n_skinning_bones = weights.shape[1]
        assert weights.shape[0] == self.n_vertices

        assert np.max(triangles) <= self.n_vertices

        if names is None:
            names = ["Bone" + str(i) for i in range(self.n_bones)]

        assert len(names) == self.n_bones

        self.mirrored = False
        self.parents = parents
        self.base_relatives = base_relatives
        self.triangles = triangles
        self.base_positions = base_positions
        self.base_normals = base_normals
        self.weights = weights
        self.names = names
        self.markers = []

        self.name_to_bone = dict((name, bone) for (bone, name) in enumerate(names))

        # Compute inverse absolutes.
        base_absolutes = relatives_to_absolutes(base_relatives, parents)
        self.inverse_base_absolutes = np.asarray([np.linalg.inv(absolute) for absolute in base_absolutes])

        self.homogeneous_base_positions = np.ones((self.n_vertices, 4))
        self.homogeneous_base_positions[:, :3] = base_positions

    
    # Computes relative rotation matrices given a set of rot_params for bones as keyword args.
    def get_posed_relatives(self, pose_params):

        relatives = self.base_relatives.copy()

        for i_bone, name in enumerate(self.names):

            T = np.eye(4)

            rot_param = pose_params[name]

            if ROTATIONAL_PARAMETERIZATION == 'axis_angle':
                T[:3, :3] = angle_axis_to_rotation_matrix(rot_param)
            else:
                # rot_param is in the order ROTATIONAL_PARAMETERIZATION
                # We must reorder it according to EULER_ANGLE_APPLICATION
                rot_param_ordered = np.zeros(3)
                for axis in ['x', 'y', 'z']:
                    rp_index = ROTATIONAL_PARAMETERIZATION.index(axis)
                    or_index = EULER_ANGLE_APPLICATION.index(axis)
                    rot_param_ordered[or_index] = rot_param[rp_index]
                T[:3, :3] = euler_angles_to_rotation_matrix(rot_param_ordered, EULER_ANGLE_APPLICATION)

            relatives[i_bone] = np.dot(relatives[i_bone], T)
        return relatives
    
    digits = ['thumb', 'index', 'middle', 'ring', 'pinky']
    def pose_in_theta_space(self, pose_params):
        # Check wrist rotation
        if np.any(pose_params['wrist'] != 0.0): return False
        # Check twist
        twists = [ v[2] for k, v in pose_params.items() if k not in ['scale', 'global_rotation', 'global_translation'] ]
        if np.any(np.array(twists) != 0.0): return False
        for d in Model.digits:
            # Check no rotation on finger root bone
            if np.any(pose_params[d + '1'] != 0.0): return False
            # Check digit abduction (bones 3 and 4)
            for i in range(3, 5):
                bone_name = d + str(i)
                if pose_params[bone_name][1] != 0.0: return False
        return True

    def get_bone_positions(self, relatives):
        absolutes = relatives_to_absolutes(relatives, self.parents)

        t = np.asarray([0.0, 0, 0, 1])
        bones = np.einsum('nij,j->ni', absolutes, t)[:, :3].copy()

        tip_indices = [self.name_to_bone[bone_name] for bone_name in ['thumb4', 'index4', 'middle4', 'ring4', 'pinky4']]
        t = np.asarray([0.0, 0.02, 0, 1])
        tips = np.einsum('nij,j->ni', absolutes[tip_indices], t)[:, :3].copy()

        return np.vstack([bones, tips])

    # Apply skinned_vertex positions.
    def get_skinned_vertex_positions(self, pose_params, apply_global=True):

        relatives = self.get_posed_relatives(pose_params)

        # Get absolute transforms from local to global space.
        absolutes = relatives_to_absolutes(relatives, self.parents)

        # Get bone transforms.
        transforms = np.einsum('nij,njk->nik', absolutes, self.inverse_base_absolutes)

        # Transform vertices by necessary transforms.
        positions = np.einsum('kij,nj->nki', transforms, self.homogeneous_base_positions)
        
        # Apply skinning.
        positions = (positions * self.weights[:, :, np.newaxis]).sum(axis=1)[:, :3]

        # Apply mirror
        if self.mirrored:
            positions[:, 0] *= -1.0

        if apply_global: positions = self.apply_global_transform(pose_params, positions)

        return positions

    def get_marker_positions(self, vertex_positions, pose_params, apply_global=True):
        result = []
        for mark_name, mark_verts in self.markers:
            position = vertex_positions[mark_verts, :].sum(axis=0) / len(mark_verts)
            if apply_global:
                position = self.apply_global_transform(pose_params, position)
            result.append((mark_name, position))
        return result

    def apply_global_transform(self, pose_params, positions):
        # Apply global rotation and translation.
        R = angle_axis_to_rotation_matrix(pose_params['global_rotation'])
        s = pose_params['scale']
        R *= s[np.newaxis,:]
        t = pose_params['global_translation']
        return np.einsum('ij,nj->ni', R, positions) + t

    def move_root_bone_rot_to_global(self, pose_params):
        rot_param = pose_params[self.names[0]]
        if np.linalg.norm(rot_param) == 0.0:
            # Nothing to do
            return

        T = np.eye(4)
        if ROTATIONAL_PARAMETERIZATION == 'axis_angle':
            T[:3, :3] = angle_axis_to_rotation_matrix(rot_param)
        else:
            T[:3, :3] = euler_angles_to_rotation_matrix(rot_param, ROTATIONAL_PARAMETERIZATION)
        R = angle_axis_to_rotation_matrix(pose_params['global_rotation'])
        addR = np.dot(self.base_relatives[0], np.dot(T, self.inverse_base_absolutes[0]))
        pose_params['global_rotation'] = rotation_matrix_to_axis_angle(np.dot(R, addR[:3, :3]))
        pose_params[self.names[0]] = np.zeros(3)

    def set_mirrored(self, mirrored=True):
        self.mirrored = mirrored

    def reset(self):
        self.mirrored = False


def relatives_to_absolutes(relatives, parents):

    n_bones = parents.shape[0]
    assert relatives.shape[0] == n_bones

    def compute_absolute(bone):

        if bone == -1:
            return np.eye(4)
        else:
            return np.dot(compute_absolute(parents[bone]), relatives[bone])

    return np.asarray([compute_absolute(bone) for bone in range(n_bones)])




def load_model(path):
    import os

    # Read in triangle info.
    triangles = np.loadtxt(os.path.join(path, 'triangles.txt'), int, delimiter=DELIM)

    # Process bones file.
    bones_path = os.path.join(path, 'bones.txt')

    # Grab bone names.
    names = [line.split(DELIM)[0] for line in open(bones_path)]

    # Grab bone parent indices.
    parents = np.loadtxt(bones_path, int, usecols=[1], delimiter=DELIM).flatten()

    # Grab relative transforms.
    transforms = np.loadtxt(bones_path, usecols=range(2, 2+16), delimiter=DELIM).reshape(len(parents), 4, 4)

    def to_floats(atoms):
        return [float(atom) for atom in atoms]

    vertices_path = os.path.join(path, 'vertices.txt')

    n_bones = len(names)

    # Find number of vertices.
    with open(vertices_path) as handle:
        n_verts = len(handle.readlines())

    # Read in vertex info.
    positions = np.zeros((n_verts, 3))
    normals = np.zeros((n_verts, 3))
    weights = np.zeros((n_verts, n_bones))
    
    with open(vertices_path) as handle:
        for i_vert, line in enumerate(handle):
            atoms = line.split(DELIM)

            positions[i_vert] = to_floats(atoms[:3])
            normals[i_vert] = to_floats(atoms[3:6])
            
            for i in range(int(atoms[8])):
                i_bone = int(atoms[9+i*2])
                weights[i_vert, i_bone] = float(atoms[9+i*2+1])

    result = Model(parents, transforms, triangles, positions, normals,  weights, names = names)

    # Grab absolute invers transforms.
    inverse_absolute_transforms = np.loadtxt(bones_path, usecols=range(2+16, 2+16+16), delimiter=DELIM).reshape(len(parents), 4, 4)

    # And push them into the result for sanity check.
    result.inverse_base_absolutes = inverse_absolute_transforms

    markers_path = os.path.join(path, '../marker_definitions.txt')
    if os.path.isfile(markers_path):
        with open(markers_path) as f:
            lines = f.readlines()
            for l in lines:
                tokens = l.replace('\n', '').split(' ')
                result.markers.append((tokens[0], [int(t) for t in tokens[2:] if len(t) > 0]))
    
    return result
