BA_NCAMPARAMS = 11  # number of camera parameters for BA

class Wishart(object):
    def __init__(self, gamma, m):
        self.gamma = gamma
        self.m = m

class Triangle(object):
    def __init__(self, verts):
        self.verts = verts