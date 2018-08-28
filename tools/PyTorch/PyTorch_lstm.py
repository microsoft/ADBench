import sys

sys.path.append(sys.path[0] + ("/" if sys.path[0] else None) + "..")
from python_common import utils
from python_common import lstm_io

import torch_wrapper
import lstm_objective as lstm

dir_in = sys.argv[1]
dir_out = sys.argv[2]
fn = sys.argv[3]
nruns_f = int(sys.argv[4])
nruns_J = int(sys.argv[5])
time_limit = int(sys.argv[6]) if len(sys.argv) >= 7 else float("inf")

fn_in = dir_in + fn
fn_out = dir_out + fn


main_params, extra_params, state, text_data = lstm_io.read_lstm_instance(fn_in + ".txt")

tf = utils.timer(torch_wrapper.torch_func, (lstm.loss, (main_params, extra_params), (state, text_data), False, True), nruns=nruns_f, limit=time_limit)

name = "PyTorch"
if nruns_J > 0:
    # k = alphas.size
    tJ, res = utils.timer(torch_wrapper.torch_func, (lstm.loss, (main_params, extra_params), (state, text_data), True, True), nruns=nruns_J, limit=time_limit, ret_val=True)
    lstm_io.write_J(fn_out + "_J_" + name + ".txt", res[1])
else:
    tJ = 0

utils.write_times(fn_out + "_times_" + name + ".txt", tf, tJ)
