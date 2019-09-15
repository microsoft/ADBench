from dataclasses import dataclass, field
from typing import Tuple
import numpy as np

@dataclass
class HandModel:
    bone_count:             int = field(default = 0)
    bone_names:             Tuple[str] = field(default = tuple())
    
    # asssuming that parent is earlier in the order of bones
    parents:                np.ndarray = field(default = np.empty(0, dtype = np.int32))
    
    base_relatives:         np.ndarray = field(default = np.empty(0, dtype = np.float64))
    inverse_base_absolutes: np.ndarray = field(default = np.empty(0, dtype = np.float64))
    base_positions:         np.ndarray = field(default = np.empty(0, dtype = np.float64))
    weights:                np.ndarray = field(default = np.empty(0, dtype = np.float64))
    
    # two dimensional array with the second dimension equals to 3
    triangles:              np.ndarray = field(default = np.empty(0, dtype = np.int32))
    is_mirrored:            bool = field(default = False)

@dataclass
class HandData:
    model:              HandModel = field(default = HandModel())
    correspondences:    np.ndarray = field(default = np.empty(0, dtype = np.int32))
    points:             np.ndarray = field(default = np.empty(0, dtype = np.float64))



@dataclass
class HandInput:
    theta:      np.ndarray = field(default = np.empty(0, dtype = np.float64))
    data:       HandData = field(default = HandData())
    us:         np.ndarray = field(default = np.empty(0, dtype = np.float64))

@dataclass
class HandOutput:
    objective:  np.ndarray = field(default = np.empty(0, dtype = np.float64))
    jacobian:   np.ndarray = field(default = np.empty(0, dtype = np.float64))

@dataclass
class HandParameters:
    is_complicated: bool = field(default = False)