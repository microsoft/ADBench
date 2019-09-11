from dataclasses import dataclass, field
import numpy as np

from BASparseMat import BASparseMat



@dataclass
class BAInput:
    cams:       np.ndarray = field(default = np.empty(0, dtype = np.float64))
    x:          np.ndarray = field(default = np.empty(0, dtype = np.float64))
    w:          np.ndarray = field(default = np.empty(0, dtype = np.float64))
    obs:        np.ndarray = field(default = np.empty(0, dtype = np.int32))
    feats:      np.ndarray = field(default = np.empty(0, dtype = np.float64))

@dataclass
class BAOutput:
    reproj_err: np.ndarray = field(default = np.empty(0, dtype = np.float64))
    w_err:      np.ndarray = field(default = np.empty(0, dtype = np.float64))
    J:          BASparseMat = field(default = BASparseMat())