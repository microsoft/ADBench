from dataclasses import dataclass, field
import numpy as np

@dataclass
class LSTMInput:
    main_params:   np.ndarray = field(default = np.empty(0, dtype = np.float64))
    extra_params:  np.ndarray = field(default = np.empty(0, dtype = np.float64))
    state:         np.ndarray = field(default = np.empty(0, dtype = np.float64))
    sequence:      np.ndarray = field(default = np.empty(0, dtype = np.float64))

@dataclass
class LSTMOutput:
    objective:     np.float64 = 0.0
    gradient:      np.ndarray = field(default = np.empty(0, dtype = np.float64))