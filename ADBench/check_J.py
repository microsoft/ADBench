import os
import math
import numpy as np

import utils

SIG_FIGS = 8
MAX_DP = 12


def load_matrix(fn):
    f = open(fn)
    lines = list(f)
    f.close()

    split_lines = map(lambda line: line.replace("\n", "").split(" "), lines)
    filtered_sl = map(lambda line: list(filter(lambda s: len(s) > 0, line)), split_lines)
    mat = list(filter(lambda row: len(row) > 3, filtered_sl))

    return mat


def round_sf(number, sf=SIG_FIGS, dp=MAX_DP):
    number = float(number)
    if number == 0:
        return 0
    else:
        rounded = round(number, math.floor(-math.log10(abs(number))) + sf)
        return round(rounded, dp)


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
        finite_files = [f for f in all_tests[test] if "Finite" in f]
        manual_files = [f for f in all_tests[test] if "Manual" in f]
        if len(finite_files) == 0:
            print(f"No Finite output for test: {test}")
            continue
        elif len(manual_files) == 0:
            print(f"No Manual output for test: {test}")
            continue

        finite_file = finite_files[0]
        manual_file = manual_files[0]

        finite_mat = load_matrix("/".join([in_dir] + graph_path + [finite_file]))
        manual_mat = load_matrix("/".join([in_dir] + graph_path + [manual_file]))

        if not test_equality(finite_mat, manual_mat, 4):
            print(f"  Manual derivatives ({manual_file}) do not match with Finite differences ({finite_file})")

        for fn in all_tests[test]:
            if fn == finite_file or fn == manual_file:
                continue

            mat = load_matrix("/".join([in_dir] + graph_path + [fn]))

            if not test_equality(mat, manual_mat):
                print(f"  Output file '{fn}' does not match with Manual derivatives ({manual_file})")
