# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import numpy as np


def read_ba_instance(fn):
    fid = open(fn, "r")
    line = fid.readline()
    line = line.split()
    n = int(line[0])
    m = int(line[1])
    p = int(line[2])

    def parse_arr(arr):
        return [float(x) for x in arr]

    one_cam = parse_arr(fid.readline().split())
    cams = np.tile(one_cam, (n, 1))

    one_X = parse_arr(fid.readline().split())
    X = np.tile(one_X, (m, 1))

    one_w = float(fid.readline())
    w = np.tile(one_w, p)

    one_feat = parse_arr(fid.readline().split())
    feats = np.tile(one_feat, (p, 1))

    fid.close()

    camIdx = 0
    ptIdx = 0
    obs = []
    for i in range(p):
        obs.append((camIdx, ptIdx))
        camIdx = (camIdx + 1) % n
        ptIdx = (ptIdx + 1) % m
    obs = np.array(obs)

    return cams, X, w, obs, feats
