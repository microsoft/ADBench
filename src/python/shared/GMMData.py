# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

from dataclasses import dataclass, field
import numpy as np

from shared.defs import Wishart
from shared.output_utils import save_value_to_file, objective_file_name,\
                            save_vector_to_file, jacobian_file_name

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

    def save_output_to_file(
        self,
        output_prefix,
        input_basename,
        module_basename
    ):
        save_value_to_file(
            objective_file_name(output_prefix, input_basename, module_basename),
            self.objective
        )

        save_vector_to_file(
            jacobian_file_name(output_prefix, input_basename, module_basename),
            self.gradient
        )


@dataclass
class GMMParameters:
    replicate_point: bool = False