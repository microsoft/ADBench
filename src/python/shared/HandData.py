
class HandInput(object):
    def __init__(self, theta, data, us):
        # float vector
        self.theta = theta
        self.data = data
        # float vector
        self.us = us

class HandOutput(object):
    def __init__(self, objective, jacobian):
        # float vector
        self.objective = objective
        # float matrix jacobian_ncols x jacobian_nrows 
        self.jacobian = jacobian

class HandParameters(object):
    def __init__(self, is_complicated):
        # bool
        self.is_complicated = is_complicated