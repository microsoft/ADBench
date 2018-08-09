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


# Read results from output files
results = {}
for test in os.listdir(tmp_dir):
    for tool in os.listdir("{}/{}".format(tmp_dir, test)):
        for filename in os.listdir("{}/{}/{}".format(tmp_dir, test, tool)):
            fn_split = filename.split(".")[0].split("_")
            if fn_split[-2] != "times":
                continue

            name = "_".join(fn_split[:-2])

            #d = int(fn_split[1][1:])
            #k = int(fn_split[2][1:])

            file = open("{}/{}/{}/{}".format(tmp_dir, test, tool, filename))
            contents = file.read()
            file.close()

            time = float(contents.replace("\n", " ").split(" ")[1])

            _set_rec(results, [test, tool, name], time)


# Plot GMM Graphs

# Create axes
figure = pyplot.figure(1)
axes = figure.add_subplot(111, projection="3d")

# Label axes
axes.set_xlabel("D values")
axes.set_ylabel("K values")
axes.set_zlabel("Time taken")

COLORS = ["b", "g", "r", "c", "m", "y", "k", "w"]

# Loop through tools
for tool in results["gmm"]:
    def getd(key):
        return int(key.split("_")[1][1:])
    
    def getk(key):
        return int(key.split("_")[2][1:])

    # Extract values
    sorted_keys = sorted(results["gmm"][tool].keys(), key=lambda key: getd(key) ** 200 + getk(key))
    d_vals = [getd(key) for key in sorted_keys]
    k_vals = [getk(key) for key in sorted_keys]

    # 3d stuff
    def getz(d, k):
        return results["gmm"][tool]["gmm_d{}_K{}".format(d, k)]
    X = numpy.array(d_vals)
    Y = numpy.array(k_vals)
    X, Y = numpy.meshgrid(X, Y)
    zs = numpy.array([getz(d, k) for d, k in zip(numpy.ravel(X), numpy.ravel(Y))])
    Z = zs.reshape(X.shape)
    # TODO not sure this is right, but test with more data

    pyplot.figure(1)
    axes.plot_wireframe(X, Y, Z, label=tool, color=COLORS[list(results["gmm"].keys()).index(tool)])
    #axes.scatter(X, Y, Z, label=tool, color=COLORS[list(results["gmm"].keys()).index(tool)])
    #axes.plot_surface(X, Y, Z)

    # Plot values
    #axes.plot(d_vals, k_vals, t_vals, label=tool)
    
    # 2d stuff
    def getn(key):
        d = int(key.split("_")[1][1:])
        k = int(key.split("_")[2][1:])
        return int(d * (d - 1) / 2 * k)
    pyplot.figure(2)
    n_vals = sorted([getn(key) for key in results["gmm"][tool]])
    t_vals_sorted = [results["gmm"][tool][key] for key in sorted(results["gmm"][tool].keys(), key=lambda key: getn(key))]
    pyplot.plot(n_vals, t_vals_sorted, marker="x", label=tool)


# Show legends
pyplot.figure(1)
pyplot.legend()

pyplot.figure(2)
pyplot.xscale("log")
pyplot.yscale("log")
pyplot.legend()

# Display figures
pyplot.show()

'''    
# Plot results
pyplot.xlabel("d * k")
pyplot.ylabel("Run Time (s)")
for tool in results["gmm"]:
    pyplot.plot(sorted(results["gmm"][tool].keys()), [results["gmm"][tool][key] for key in sorted(results["gmm"][tool].keys())], marker="x", label=tool)
    
pyplot.legend()
#pylab.savefig("graphs.png")
pyplot.show()

'''
