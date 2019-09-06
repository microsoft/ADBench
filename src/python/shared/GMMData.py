class GMMInput(object):
    def __init__(self, alphas, means, icf, x, wishart):
        self.alphas = alphas
        self.means = means
        self.icf = icf
        self.x = x
        self.wishart = wishart

class GMMOutput(object):
    def __init__(self, objective, gradient):
        self.objective = objective
        self.gradient = gradient

class GMMParameters(object):
    def __init__(self, replicate_point):
        self.replicate_point = replicate_point