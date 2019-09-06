
class LSTMInput(object):
    def __init__(self, main_params, extra_params, state, sequence):
        # float matrix b x l 
        self.main_params = main_params
        # float vector b
        self.extra_params = extra_params
        # float matrix b x l
        self.state = state
        # float matrix b x c
        self.sequence = sequence

class LSTMOutput(object):
    def __init__(self, objective, gradient):
        # float
        self.objective = objective
        # float vector
        self.gradient = gradient