import numpy as np


# Read GMM instance from file
def read_gmm_instance(fn, replicate_point):
    fid = open(fn, "r")
    line = fid.readline()
    line = line.split()
    d = int(line[0])
    k = int(line[1])
    n = int(line[2])
    alphas = np.array([float(fid.readline()) for i in range(k)])

    def parse_arr(arr):
        return [float(x) for x in arr]
    means = np.array([parse_arr(fid.readline().split()) for i in range(k)])
    icf = np.array([parse_arr(fid.readline().split()) for i in range(k)])
    if replicate_point:
        x_ = parse_arr(fid.readline().split())
        x = np.array([x_ for i in range(n)])
    else:
        x = np.array([parse_arr(fid.readline().split()) for i in range(n)])
    line = fid.readline().split()
    wishart_gamma = float(line[0])
    wishart_m = int(line[1])
    fid.close()
    return alphas, means, icf, x, wishart_gamma, wishart_m


# Write results to file
def write_J(fn, grad):
    fid = open(fn, "w")
    J = np.concatenate((grad[0], grad[1].flatten(), grad[2].flatten()))
    print("%i %i" % (1, J.size), file=fid)
    line = ""
    for elem in J:
        line = line + ("%f " % elem)
    print(line, file=fid)
    fid.close()
