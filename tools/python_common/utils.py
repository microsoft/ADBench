import time as t


# Time execution of a function
def timer(func, args, nruns=10, limit=float("inf"), ret_val=False):
    total, i = 0, 0
    value = None
    while i < nruns and total < limit:
        start = t.time()
        value = func(*args)
        end = t.time()
        total += end - start
        i += 1
    result = total / nruns if nruns > 0 else 0
    return (result, value) if ret_val else result


# Write times to file
def write_times(fn, tf, tJ):
    fid = open(fn, "w")
    print("%f %f" % (tf, tJ), file=fid)
    print("tf tJ", file=fid)
    fid.close()
