import os

# UTIL FUNCTIONS


# Recursively set in nested dictionary
def _set_rec(obj, keys, value):
    if len(keys) == 1:
        obj[keys[0]] = value
        return obj
    else:
        if keys[0] in obj:
            obj[keys[0]] = _set_rec(obj[keys[0]], keys[1:], value)
        else:
            obj[keys[0]] = _set_rec({}, keys[1:], value)

        return obj


# Recursively scan a directory
def _scandir_rec(folder, depth=0):
    folder = folder.strip("/") + "/"
    if len(os.listdir(folder)) > 0 and os.path.isdir(folder + os.listdir(folder)[0]):
        results = []
        for fn in os.listdir(folder):
            results += [[fn] + file_name for file_name in _scandir_rec(folder + fn, depth + 1)]
    else:
        results = [[fn] for fn in os.listdir(folder)]
    # results = [[folder.split("/")[-2]] + fn for fn in results]
    return results


# Recursively make directories for file/directory
def _mkdir_if_none(path):
    if not os.path.exists(path):
        if len(os.path.splitext(path)[1]) > 0:
            _mkdir_if_none(os.path.dirname(path))
        else:
            os.makedirs(path)


# Capitalise the first letter of a string, but leave others unaffected
def cap_str(s):
    return s[0].upper() + (s[1:] if len(s) > 1 else "")


# Extract filename (no ext) from path
def get_fn(path):
    return path[-1].split(".")[0]


# Extract tool name from filename
def get_tool(fn):
    return "_".join(fn.split("_")[fn.split("_").index("times") + 1:])


# Format a tool name for display
def format_tool(tool):
    t_split = list(map(cap_str, tool.split("_")))
    return cap_str(t_split[0]) + ((" (" + ", ".join(t_split[1:]) + ")") if len(t_split) > 1 else "")


# Extract the test (i.e. type and size) from a filename
def get_test(fn):
    return "_".join(fn.split("_")[:fn.split("_").index("times")])


# Read a time from a file
def read_time(path, func_type):
    file = open(path)
    times = file.read().replace("\n", " ").split(" ")
    file.close()

    func_times = {
        "objective": lambda times: float(times[0]),
        "jacobian": lambda times: float(times[1]),
        "jacobian ÷ objective": lambda times: float(times[1]) / float(times[0]),
    }

    return func_times[func_type](times)


# Get the GMM D value from a key
def gmm_get_d(key):
    return int(key.split("_")[1][1:])


# Get the GMM K value from a key
def gmm_get_k(key):
    return int(key.split("_")[2][1:])


# Get the problem size from a GMM key
def gmm_get_n(key):
    return int(gmm_get_d(key) * (gmm_get_d(key) - 1) / 2 * gmm_get_k(key))


# Get the problem size from a standard (BA, hand) key
def std_get_n(key):
    return int("".join([c for c in key if c.isdigit()]))


# All (key->problem size) functions for different objectives
key_functions = {
    "gmm": gmm_get_n,
    "ba": std_get_n,
    "hand": std_get_n
}
