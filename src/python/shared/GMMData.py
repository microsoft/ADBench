from dataclasses import dataclass, field
from typing import List
from shared.defs import Wishart

@dataclass
class GMMInput:
    alphas:     List[float] = field(default_factory = list)
    means:      List[float] = field(default_factory = list)
    icf:        List[float] = field(default_factory = list)
    x:          List[float] = field(default_factory = list)
    wishart:    Wishart = field(default_factory = Wishart)

@dataclass
class GMMOutput:
    objective: float = 0.0
    gradient: List[float] = field(default_factory = list)

@dataclass
class GMMParameters:
    replicate_point: bool = False