class LSTMInput(object):
    def __init__(self, main_params, extra_params, state, sequence):
        self.main_params = main_params
        self.extra_params = extra_params
        self.state = state
        self.sequence = sequence

class LSTMOutput(object):
    def __init__(self, objective, gradient):
        self.objective = objective
        self.gradient = gradient