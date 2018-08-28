import os
import math
import numpy as np

import utils

SIG_FIGS = 3


def load_matrix(fn):
    f = open(fn)
    lines = list(f)
    f.close()

    split_lines = map(lambda line: line.replace("\n", "").split(" "), lines)
    filtered_sl = map(lambda line: list(filter(lambda s: len(s) > 0, line)), split_lines)
    mat = list(filter(lambda row: len(row) > 3, filtered_sl))

    return mat


def round_sf(number, sf=SIG_FIGS):
    number = float(number)
    if number == 0:
        return 0
    else:
        return round(number, math.floor(-math.log10(abs(number))) + sf)


def test_equality(mat1, mat2, sf=SIG_FIGS):
    if len(mat1) != len(mat2):
        return False

    for i in range(len(mat1)):
        if len(mat1[i]) != len(mat2[i]):
            return False

        for j in range(len(mat1[i])):
            if round_sf(mat1[i][j], sf) != round_sf(mat2[i][j], sf):
                return False

    return True


# Folders
adbench_dir = os.path.dirname(os.path.realpath(__file__))
ad_root_dir = os.path.dirname(adbench_dir)
in_dir = f"{ad_root_dir}/tmp"


# Scan folder for all files, and determine which graphs to create
all_files = [path for path in utils._scandir_rec(in_dir) if "times" in path[-1]]
all_graphs = [path.split("/") for path in list(set(["/".join(path[:-2]) for path in all_files]))]

for graph_path in all_graphs:
    print("Finding files for graph:", "/".join(graph_path))
    tools = os.listdir("/".join([in_dir] + graph_path))
    all_tests = {}
    for tool in tools:
        tool_files = os.listdir("/".join([in_dir] + graph_path + [tool]))
        time_files = [fn for fn in tool_files if "_times_" in fn]
        files = [fn for fn in tool_files if "_J_" in fn]

        if len(time_files) > len(files):
            print("  May be missing some Jacobian output files for: " + "/".join(graph_path + [tool]))

        tests = {fn[:fn.find("_J_")]: f"{tool}/{fn}" for fn in files}
        for test in tests:
            if test in all_tests:
                all_tests[test].append(tests[test])
            else:
                all_tests[test] = [tests[test]]

    print("Comparing files for graph:", "/".join(graph_path))

    for test in all_tests:
        last_mat = None
        for i in range(len(all_tests[test])):
            fn = all_tests[test][i]
            mat = load_matrix("/".join([in_dir] + graph_path + [fn]))

            if last_mat is not None:
                print(f"  Compare {fn} to {all_tests[test][i - 1]} in {'/'.join(graph_path)}")
                if not test_equality(mat, last_mat):
                    print("    Mismatch in file:", "/".join(graph_path + [fn]))

            last_mat = mat
