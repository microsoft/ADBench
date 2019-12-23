# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

from dataclasses import dataclass, field
import numpy as np

from shared.BASparseMat import BASparseMat
from shared.output_utils import save_errors_to_file, objective_file_name,\
                            save_sparse_j_to_file, jacobian_file_name



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

    def save_output_to_file(
        self,
        output_prefix,
        input_basename,
        module_basename
    ):
        save_errors_to_file(
            objective_file_name(output_prefix, input_basename, module_basename),
            self.reproj_err,
            self.w_err
        )

        save_sparse_j_to_file(
            jacobian_file_name(output_prefix, input_basename, module_basename),
            self.J
        )