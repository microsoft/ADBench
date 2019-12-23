# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import os
import sys
sys.path.append(sys.path[0] + ("/" if sys.path[0] else None) + "..")
from shared import GMMData
from shared import BAData
from shared import HandData
from shared import LSTMData
from shared import input_utils
from runner.Filepaths import filepath_to_dirname
from runner.Benchmark import run_benchmark

# function printing to stderr
def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

def main(argv):
    try:
        if (len(argv) < 9):
            eprint("usage: PythonRunner test_type module_path input_filepath " +\
                "output_dir minimum_measurable_time nruns_F nruns_J time_limit [-rep]\n")
            return 1

        test_type = argv[1]
        module_path = os.path.normpath(argv[2])
        input_filepath = os.path.normpath(argv[3])
        output_prefix = os.path.normpath(argv[4])
        minimum_measurable_time = float(argv[5])
        nruns_F = int(argv[6])
        nruns_J = int(argv[7])
        time_limit = float(argv[8])

        # read only 1 point and replicate it?
        replicate_point = (len(argv) > 9 and str(argv[9]) == "-rep")

        # If the given prefix is a directory then add a separator to its end
        # thus we can just use concatenation further
        if os.path.isdir(output_prefix):
            output_prefix += os.path.sep

        if test_type == "GMM":
            # read gmm input
            _input = input_utils.read_gmm_instance(input_filepath, replicate_point)
        elif test_type == "BA":
            # read ba input
            _input = input_utils.read_ba_instance(input_filepath)
        elif test_type == "HAND":
            model_dir = os.path.join(filepath_to_dirname(input_filepath), "model")
            # read hand input
            _input = input_utils.read_hand_instance(model_dir, input_filepath, False)
        elif test_type == "HAND-COMPLICATED":
            model_dir = os.path.join(filepath_to_dirname(input_filepath), "model")
            # read hand complicated input
            _input = input_utils.read_hand_instance(model_dir, input_filepath, True)
        elif test_type == "LSTM":
            _input = input_utils.read_lstm_instance(input_filepath)
        else:
            raise RuntimeError("Python runner doesn't support tests of " + test_type + " type")

        run_benchmark(
            module_path,
            input_filepath,
            _input,
            output_prefix,
            minimum_measurable_time,
            nruns_F,
            nruns_J,
            time_limit
        )

    except RuntimeError as ex:
        eprint("Runtime exception caught: ", ex)
    except Exception as ex:
        eprint("An exception caught: ", ex)

    return 0

if __name__ == "__main__":
    main(sys.argv[:])