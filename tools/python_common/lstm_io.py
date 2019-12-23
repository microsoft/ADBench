# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import math

import numpy as np


def text_to_matrix(text, bits):
    # bits = math.ceil(math.log2(max([ord(c) for c in text])))
    return np.array(list(map(lambda c: list(map(lambda b: float(b), bin(ord(c))[2:].zfill(bits))), text)))


def read_lstm_instance(fn):
    fid = open(fn)

    line = fid.readline().split()
    layer_count = int(line[0])
    char_count = int(line[1])
    char_bits = int(line[2])

    fid.readline()

    def parse_arr(arr):
        return [float(x) for x in arr]

    main_params = np.array([parse_arr(fid.readline().split()) for i in range(2 * layer_count)])
    fid.readline()
    extra_params = np.array([parse_arr(fid.readline().split()) for i in range(3)])
    fid.readline()
    state = np.array([parse_arr(fid.readline().split()) for i in range(2 * layer_count)])
    fid.readline()
    text_mat = np.array([parse_arr(fid.readline().split()) for i in range(char_count)])

    fid.close()

    return main_params, extra_params, state, text_mat


def f_write_mat(fid, matrix):
    for row in matrix:
        fid.write(" ".join(["%f" % n for n in row]))
        fid.write("\n")


def write_J(fn, grad):
    fid = open(fn, "w")
    fid.write(f"1 {grad.shape[1]}\n")
    f_write_mat(fid, grad)
    fid.close()
