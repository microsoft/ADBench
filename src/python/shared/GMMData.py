from dataclasses import dataclass, field
import numpy as np
from defs import Wishart

@dataclass
class GMMInput:
    alphas:     np.ndarray = field(default = np.empty(0, dtype = np.float64))
    means:      np.ndarray = field(default = np.empty(0, dtype = np.float64))
    icf:        np.ndarray = field(default = np.empty(0, dtype = np.float64))
    x:          np.ndarray = field(default = np.empty(0, dtype = np.float64))
    wishart:    Wishart = field(default = Wishart())

@dataclass
class GMMOutput:
    objective: np.float64 = 0.0
    gradient: np.ndarray = field(default = np.empty(0, dtype = np.float64))

@dataclass
class GMMParameters:
    replicate_point: bool = False