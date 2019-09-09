from dataclasses import dataclass, field
from typing import List
BA_NCAMPARAMS = 11  # number of camera parameters for BA

@dataclass
class Wishart:
    gamma: float = 0.0
    m: int = 0

@dataclass
class Triangle:
    verts: List[int] = field(default_factory = list)