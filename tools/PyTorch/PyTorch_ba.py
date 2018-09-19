import sys

import numpy as np

sys.path.append(sys.path[0] + ("/" if sys.path[0] else None) + "..")
from python_common import utils
from python_common import ba_io

import torch_wrapper
import ba_objective as ba

dir_in = sys.argv[1]
dir_out = sys.argv[2]
fn = sys.argv[3]
nruns_f = int(sys.argv[4])
nruns_J = int(sys.argv[5])
time_limit = int(sys.argv[6]) if len(sys.argv) >= 7 else float("inf")

fn_in = dir_in + fn
fn_out = dir_out + fn

cams, X, w, obs, feats = ba_io.read_ba_instance(fn_in + ".txt")

tf = utils.timer(torch_wrapper.torch_func, (ba.ba_objective, (cams, X, w), (obs, feats), False), nruns=nruns_f, limit=time_limit)

name = "PyTorch"
if nruns_J > 0:
    tJ, res = utils.timer(torch_wrapper.torch_func, (ba.ba_objective, (cams, X, w), (obs, feats), True), nruns=nruns_J, limit=time_limit)
    J = res[1]
    # TODO write J to file for comparison testing
    # gmm.write_J(fn_out + "_J_" + name + ".txt",grad[1])
else:
    tJ = 0

utils.write_times(fn_out + "_times_" + name + ".txt", tf, tJ)
