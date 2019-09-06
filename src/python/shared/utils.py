
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