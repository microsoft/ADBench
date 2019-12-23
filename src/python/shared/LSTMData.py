# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

from dataclasses import dataclass, field
import numpy as np

from shared.output_utils import save_value_to_file, objective_file_name,\
                            save_vector_to_file, jacobian_file_name

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