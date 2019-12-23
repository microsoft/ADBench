# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

from dataclasses import dataclass, field
from typing import Tuple
from numpy import float64, int32

# BA global parameters
BA_NCAMPARAMS = 11  # number of camera parameters for BA
ROT_IDX = 0
C_IDX = 3
F_IDX = 6
X0_IDX = 7
RAD_IDX = 9

@dataclass
class Wishart:
    gamma:  float64 = 0.0
    m:      int32 = 0