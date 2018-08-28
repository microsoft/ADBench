import sys
import os
import time as t

import numpy as np
import torch

sys.path.append(sys.path[0] + ("/" if sys.path[0] else None) + "..")
from python_common import utils
from python_common import hand_io

import torch_wrapper
from hand_objective import hand_objective_complicated


# Wrapper to repeat function with different seeds
def torch_seed_wrapper(seed, args):
    J = []
    res = torch_wrapper.torch_func(*args)
    for curr_seed in seed:
        J.append(res[1] @ curr_seed)
    return res[0], torch.stack(J).transpose(0, 1)


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

    params, us, data = hand_io.read_hand_instance(model_dir, fn_in + ".txt", True)
    all_params = np.append(us.flatten(), params)
    if data.model.is_mirrored:
        mirror_factor = -1.
    else:
        mirror_factor = 1.

    tf, err = utils.timer(torch_wrapper.torch_func, (
        hand_objective_complicated,
        (all_params,),
        (data.model.nbones, data.model.base_relatives, data.model.parents,
            data.model.inverse_base_absolutes, data.model.base_positions,
            data.model.weights, mirror_factor, data.points,
            data.correspondences, data.model.triangles),
        False
    ), nruns=nruns_f, limit=time_limit, ret_val=True)
    # print("err:")
    # print(err)

    name = "PyTorch"

    ntheta = params.shape[0]
    npts = us.shape[0]
    seed = torch.zeros((2 + ntheta, all_params.shape[0]), dtype=torch.float64)
    for i in range(npts):
        seed[0][2 * i] = 1.
        seed[1][2 * i + 1] = 1.
    for i in range(ntheta):
        seed[i + 2][i + 2 * npts] = 1.

    if nruns_J > 0:
        tJ, res = utils.timer(lambda *args: torch_seed_wrapper(seed, args), (
            hand_objective_complicated,
            (all_params,),
            (data.model.nbones, data.model.base_relatives, data.model.parents,
                data.model.inverse_base_absolutes, data.model.base_positions,
                data.model.weights, mirror_factor, data.points,
                data.correspondences, data.model.triangles),
            True
        ), nruns=nruns_J, limit=time_limit, ret_val=True)
        tJ += tf  # !!!!!!!!! adding this because no function value is returned by fjac
        # print("J:")
        # print(J)
        print(res[1].shape)
        hand_io.write_J(fn_out + "_J_" + name + ".txt", res[1])
    else:
        tJ = 0

    utils.write_times(fn_out + "_times_" + name + ".txt", tf, tJ)
