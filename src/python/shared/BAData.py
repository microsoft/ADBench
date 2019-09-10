from dataclasses import dataclass, field
from typing import List

from BASparseMat import BASparseMat



@dataclass
class BAInput:
    cams:       List[float] = field(default_factory = list)
    X:          List[float] = field(default_factory = list)
    w:          List[float] = field(default_factory = list)
    feats:      List[float] = field(default_factory = list)
    obs:        List[int] = field(default_factory = list)

@dataclass
class BAOutput:
    reproj_err: List[float] = field(default_factory = list)
    w_err:      List[float] = field(default_factory = list)
    J:          BASparseMat = field(default_factory = BASparseMat)