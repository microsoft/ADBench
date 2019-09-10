from dataclasses import dataclass, field
from typing import List

# BA global parameters
BA_NCAMPARAMS = 11  # number of camera parameters for BA
ROT_IDX = 0
C_IDX = 3
F_IDX = 6
X0_IDX = 7
RAD_IDX = 9

@dataclass
class Wishart:
    gamma: float = 0.0
    m: int = 0

@dataclass
class Triangle:
    verts: List[int] = field(default_factory = list)