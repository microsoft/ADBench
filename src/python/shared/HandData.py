class HandInput(object):
    def __init__(self, theta, data, us):
        self.theta = theta
        self.data = data
        self.us = us

class HandOutput(object):
    def __init__(self, objective, jacobian):
        self.objective = objective
        self.jacobian = jacobian

class HandParameters(object):
    def __init__(self, is_complicated):
        self.is_complicated = is_complicated