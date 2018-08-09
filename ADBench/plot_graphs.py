import os
import numpy
from matplotlib import pylab, pyplot
from mpl_toolkits.mplot3d import Axes3D

tmp_dir = "../tmp"

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


# READ IN RESULTS FROM OUTPUT FILES

results = {}
for test in os.listdir(tmp_dir):
    for tool in os.listdir("{}/{}".format(tmp_dir, test)):
        for filename in os.listdir("{}/{}/{}".format(tmp_dir, test, tool)):
            fn_split = filename.split(".")[0].split("_")
            if fn_split[-2] != "times":
                continue

            name = "_".join(fn_split[:-2])

            file = open("{}/{}/{}/{}".format(tmp_dir, test, tool, filename))
            contents = file.read()
            file.close()

            time = float(contents.replace("\n", " ").split(" ")[1])

            _set_rec(results, [test, tool, name], time)


# PLOT GMM GRAPHS

# Create axes
figure = pyplot.figure(1)
axes = figure.add_subplot(111, projection="3d")

# Label axes
axes.set_xlabel("D values")
axes.set_ylabel("K values")
axes.set_zlabel("Time taken")

# Color constants
COLORS = ["b", "g", "r", "c", "m", "y", "k", "w"]

# Lambda functions to sort results
getd = lambda key: int(key.split("_")[1][1:])
getk = lambda key: int(key.split("_")[2][1:])
getn = lambda key: int(getd(key) * (getd(key) - 1) / 2 * getk(key))
getkey = lambda d, k: "gmm_d{}_K{}".format(d, k)
getz = lambda d, k: results["gmm"][tool][getkey(d, k)] if getkey(d, k) in results["gmm"][tool] else float("inf")

# Loop through tools
for tool in results["gmm"]:
    # 3D Plot
    pyplot.figure(1)

    # Get values
    d_vals = numpy.unique(list(map(getd, results["gmm"][tool])))
    k_vals = numpy.unique(list(map(getk, results["gmm"][tool])))
    X = numpy.repeat([d_vals], len(k_vals), 0)
    Y = numpy.repeat([[k] for k in k_vals], len(d_vals), 1)
    Z = numpy.array([[getz(X[i, j], Y[i, j]) for j in range(len(d_vals))] for i in range(len(k_vals))])

    # Plot
    axes.plot_wireframe(X, Y, Z, label=tool, color=COLORS[list(results["gmm"].keys()).index(tool)])
    #axes.scatter(X, Y, Z, label=tool, color=COLORS[list(results["gmm"].keys()).index(tool)])
    #axes.plot_surface(X, Y, Z, color=COLORS[list(results["gmm"].keys()).index(tool)])
    
    # 2D plot
    pyplot.figure(2)

    # Get values
    key_n_vals = {key: getn(key) for key in results["gmm"][tool]}
    n_vals = sorted(key_n_vals.values())
    t_vals = [results["gmm"][tool][key] for key in sorted(key_n_vals.keys(), key=lambda key: key_n_vals[key])]

    # Plot
    pyplot.plot(n_vals, t_vals, marker="x", label=tool)


# Show 3D legend
pyplot.figure(1)
pyplot.legend()

# Show 2D legend, and log-scale axes
pyplot.figure(2)
pyplot.xscale("log")
pyplot.yscale("log")
pyplot.legend()


# PLOT BA GRAPHS

pyplot.figure(3)

#for tool in results["ba"]:
#    pass # TODO

pyplot.legend()

# Display all figures
pyplot.show()
