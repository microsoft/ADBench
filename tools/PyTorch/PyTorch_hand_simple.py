import sys
import os
import time as t

import numpy as np

sys.path.append(sys.path[0] + ("/" if sys.path[0] else None) + "..")
from python_common import utils
from python_common import hand_io

import torch_wrapper
from hand_objective import hand_objective


ntasks = (len(sys.argv) - 1) // 5
time_limit = int(sys.argv[-1]) if len(sys.argv) >= (ntasks * 5 + 2) else float("inf")
for task_id in range(ntasks):
    # print("task_id: %i" % task_id)

    argv_idx = task_id * 5 + 1
    dir_in = sys.argv[argv_idx]
    dir_out = sys.argv[argv_idx + 1]
    fn = sys.argv[argv_idx + 2]
    nruns_f = int(sys.argv[argv_idx + 3])
    nruns_J = int(sys.argv[argv_idx + 4])

    model_dir = dir_in + "model/"
    fn_in = dir_in + fn
    fn_out = dir_out + fn

    params, data = hand_io.read_hand_instance(model_dir, fn_in + ".txt", False)
    if data.model.is_mirrored:
        mirror_factor = -1.
    else:
        mirror_factor = 1.

    tf, err = utils.timer(torch_wrapper.torch_func, (
        hand_objective,
        (params,),
        (data.model.nbones, data.model.base_relatives, data.model.parents,
            data.model.inverse_base_absolutes, data.model.base_positions,
            data.model.weights, mirror_factor, data.points,
            data.correspondences),
        False
    ), nruns=nruns_f, limit=time_limit, ret_val=True)
    # print("err:")
    # print(err)

    name = "PyTorch"

    if nruns_J > 0:
        tJ, res = utils.timer(torch_wrapper.torch_func, (
            hand_objective,
            (params,),
            (data.model.nbones, data.model.base_relatives, data.model.parents,
                data.model.inverse_base_absolutes, data.model.base_positions,
                data.model.weights, mirror_factor, data.points,
                data.correspondences),
            True
        ), nruns=nruns_J, limit=time_limit, ret_val=True)
        tJ += tf  # !!!!!!!!! adding this because no function value is returned by fjac
        # print("J:")
        # print(J)
        hand_io.write_J(fn_out + "_J_" + name + ".txt", res[1].reshape((res[1].shape[0], res[1].shape[2])))
    else:
        tJ = 0

    utils.write_times(fn_out + "_times_" + name + ".txt", tf, tJ)
