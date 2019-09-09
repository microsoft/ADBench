import os
import numpy as np

DELIM = ':'

# GMM io
def read_gmm_instance(fn, replicate_point):
    fid = open(fn, "r")
    line = fid.readline()
    line = line.split()
    d = int(line[0])
    k = int(line[1])
    n = int(line[2])
    alphas = np.array([float(fid.readline()) for i in range(k)])

    def parse_arr(arr):
        return [float(x) for x in arr]
    means = np.array([parse_arr(fid.readline().split()) for i in range(k)])
    icf = np.array([parse_arr(fid.readline().split()) for i in range(k)])
    if replicate_point:
        x_ = parse_arr(fid.readline().split())
        x = np.array([x_ for i in range(n)])
    else:
        x = np.array([parse_arr(fid.readline().split()) for i in range(n)])
    line = fid.readline().split()
    wishart_gamma = float(line[0])
    wishart_m = int(line[1])
    fid.close()
    return alphas, means, icf, x, wishart_gamma, wishart_m

# BA io
def read_ba_instance(fn):
    fid = open(fn, "r")
    line = fid.readline()
    line = line.split()
    n = int(line[0])
    m = int(line[1])
    p = int(line[2])

    def parse_arr(arr):
        return [float(x) for x in arr]

    one_cam = parse_arr(fid.readline().split())
    cams = np.tile(one_cam, (n, 1))

    one_X = parse_arr(fid.readline().split())
    X = np.tile(one_X, (m, 1))

    one_w = float(fid.readline())
    w = np.tile(one_w, p)

    one_feat = parse_arr(fid.readline().split())
    feats = np.tile(one_feat, (p, 1))

    fid.close()

    camIdx = 0
    ptIdx = 0
    obs = []
    for i in range(p):
        obs.append((camIdx, ptIdx))
        camIdx = (camIdx + 1) % n
        ptIdx = (ptIdx + 1) % m
    obs = np.array(obs)

    return cams, X, w, obs, feats

# Hand io
class HandModel(object):
    def __init__(self, parents, base_relatives, inverse_base_absolutes, triangles, base_positions, weights, nbones, is_mirrored = False):
        self.nbones = nbones
        self.parents = parents
        self.base_relatives = base_relatives
        self.inverse_base_absolutes = inverse_base_absolutes
        self.base_positions = base_positions
        self.weights = weights
        self.triangles = triangles
        self.is_mirrored = is_mirrored


class HandData(object):
    def __init__(self, model, correspondences, points):
        self.model = model
        self.correspondences = correspondences
        self.points = points

def load_model(path):
    # Read in triangle info.
    triangles = np.loadtxt(os.path.join(
        path, 'triangles.txt'), int, delimiter=DELIM)

    # Process bones file.
    bones_path = os.path.join(path, 'bones.txt')

    # Grab bone names.
    bone_names = [line.split(DELIM)[0] for line in open(bones_path)]

    # Grab bone parent indices.
    parents = np.loadtxt(bones_path, int, usecols=[
                         1], delimiter=DELIM).flatten()

    # Grab relative transforms.
    relative_transforms = np.loadtxt(bones_path, usecols=range(
        2, 2 + 16), delimiter=DELIM).reshape(len(parents), 4, 4)

    def to_floats(atoms):
        return [float(atom) for atom in atoms]

    vertices_path = os.path.join(path, 'vertices.txt')

    n_bones = len(bone_names)

    # Find number of vertices.
    with open(vertices_path) as handle:
        n_verts = len(handle.readlines())

    # Read in vertex info.
    positions = np.zeros((n_verts, 3))
    weights = np.zeros((n_verts, n_bones))

    with open(vertices_path) as handle:
        for i_vert, line in enumerate(handle):
            atoms = line.split(DELIM)

            positions[i_vert] = to_floats(atoms[:3])

            for i in range(int(atoms[8])):
                i_bone = int(atoms[9 + i * 2])
                weights[i_vert, i_bone] = float(atoms[9 + i * 2 + 1])

    # Grab absolute invers transforms.
    inverse_absolute_transforms = np.loadtxt(bones_path, usecols=range(
        2 + 16, 2 + 16 + 16), delimiter=DELIM).reshape(len(parents), 4, 4)

    n_vertices = positions.shape[0]
    homogeneous_base_positions = np.ones((n_vertices, 4))
    homogeneous_base_positions[:, :3] = positions

    result = HandModel(parents, relative_transforms, inverse_absolute_transforms,
                       triangles, homogeneous_base_positions, weights, n_bones)

    return result

def read_hand_instance(model_dir, fn, read_us):
    model = load_model(model_dir)

    fid = open(fn, "r")
    line = fid.readline()
    line = line.split()
    npts = int(line[0])
    ntheta = int(line[1])

    lines = [fid.readline().split() for i in range(npts)]

    correspondences = np.array([int(line[0]) for line in lines])

    points = np.array([[float(line[i])
                        for i in range(1, len(line))] for line in lines])

    if read_us:
        us = np.array([[float(elem) for elem in fid.readline().split()]
                       for i_pt in range(npts)])

    params = np.array([float(fid.readline()) for i in range(ntheta)])
    fid.close()

    data = HandData(model, correspondences, points)

    if read_us:
        return params, us, data
    else:
        return params, data

# LSTM io
def read_lstm_instance(fn):
    fid = open(fn)

    line = fid.readline().split()
    layer_count = int(line[0])
    char_count = int(line[1])
    char_bits = int(line[2])

    fid.readline()

    def parse_arr(arr):
        return [float(x) for x in arr]

    main_params = np.array([parse_arr(fid.readline().split()) for i in range(2 * layer_count)])
    fid.readline()
    extra_params = np.array([parse_arr(fid.readline().split()) for i in range(3)])
    fid.readline()
    state = np.array([parse_arr(fid.readline().split()) for i in range(2 * layer_count)])
    fid.readline()
    text_mat = np.array([parse_arr(fid.readline().split()) for i in range(char_count)])

    fid.close()

    return main_params, extra_params, state, text_mat