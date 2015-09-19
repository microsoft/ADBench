import os

import numpy as np

DELIM=':'

class HandModel(object):

    def __init__(self, parents, base_relatives, inverse_base_absolutes, triangles, base_positions, weights, nbones):
        self.nbones = nbones
        self.parents = parents
        self.base_relatives = base_relatives
        self.inverse_base_absolutes = inverse_base_absolutes
        self.base_positions = base_positions
        self.weights = weights
        self.triangles = triangles
        self.is_mirrored = False

class HandData(object):

    def __init__(self, model, correspondences, points):
        self.model = model
        self.correspondences = correspondences
        self.points = points

def load_model(path):
    # Read in triangle info.
    triangles = np.loadtxt(os.path.join(path, 'triangles.txt'), int, delimiter=DELIM)

    # Process bones file.
    bones_path = os.path.join(path, 'bones.txt')

    # Grab bone names.
    bone_names = [line.split(DELIM)[0] for line in open(bones_path)]

    # Grab bone parent indices.
    parents = np.loadtxt(bones_path, int, usecols=[1], delimiter=DELIM).flatten()

    # Grab relative transforms.
    relative_transforms = np.loadtxt(bones_path, usecols=range(2, 2+16), delimiter=DELIM).reshape(len(parents), 4, 4)

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
                i_bone = int(atoms[9+i*2])
                weights[i_vert, i_bone] = float(atoms[9+i*2+1])

    # Grab absolute invers transforms.
    inverse_absolute_transforms = np.loadtxt(bones_path, usecols=range(2+16, 2+16+16), delimiter=DELIM).reshape(len(parents), 4, 4)
    
    n_vertices = positions.shape[0]
    homogeneous_base_positions = np.ones((n_vertices, 4))
    homogeneous_base_positions[:, :3] = positions

    result = HandModel(parents, relative_transforms, inverse_absolute_transforms, triangles, homogeneous_base_positions,  weights, n_bones)

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

    points = np.array([[float(line[i]) for i in range(1,len(line))] for line in lines])
    
    if read_us:
        us = np.array([[float(elem) for elem in fid.readline().split()] for i_pt in range(npts)])

    params = np.array([float(fid.readline()) for i in range(ntheta)])
    fid.close()

    data = HandData(model, correspondences, points)

    if read_us:
        return params, us, data
    else:
        return params, data

def write_times(fn,tf,tJ):
    fid = open(fn, "w")
    print("%f %f" % (tf,tJ) , file = fid)
    print("tf tJ" , file = fid)
    fid.close()
    
def write_J(fn,J):
    fid = open(fn, "w")
    print("%i %i" % (J.shape[0],J.shape[1]) , file = fid)
    line = ""
    for row in J:
        for elem in row:
            line += ("%f " % elem)
        line += "\n"
    print(line,file = fid)
    fid.close()