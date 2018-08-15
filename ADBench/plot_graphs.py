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
for build in os.listdir(tmp_dir):
    for test in os.listdir("/".join([tmp_dir, build])):
        for tool in os.listdir("/".join([tmp_dir, build, test])):
            for filename in os.listdir("/".join([tmp_dir, build, test, tool])):
                fn_split = filename.split(".")[0].split("_")
                if "times" not in fn_split:
                    continue

                name = "_".join(fn_split[:fn_split.index("times")])

                tool_name = [s.capitalize() for s in fn_split[fn_split.index("times") + 1:]]
                if len(tool_name) > 1:
                    tool_name = "{} ({})".format(tool_name[0], " ".join(tool_name[1:]))
                else:
                    tool_name = tool_name[0]

                file = open("/".join([tmp_dir, build, test, tool, filename]))
                contents = file.read()
                file.close()

                time = float(contents.replace("\n", " ").split(" ")[1])

                _set_rec(results, [build, test, tool_name, name], time)


plot_idx = 0
for build in results:
    # PLOT GMM GRAPHS

    # Create axes
    figure = pyplot.figure(plot_idx + 1)
    pyplot.title("GMM")
    axes = figure.add_subplot(111, projection="3d")

    # Label axes
    axes.set_xlabel("D values")
    axes.set_ylabel("K values")
    axes.set_zlabel("Time taken")

    # Functions to sort results
    def getd(key):
        return int(key.split("_")[1][1:])

    def getk(key):
        return int(key.split("_")[2][1:])

    def getn(key):
        return int(getd(key) * (getd(key) - 1) / 2 * getk(key))

    def getkey(d, k):
        return "gmm_d{}_K{}".format(d, k)

    def getz(d, k):
        return results[build]["gmm"][tool][getkey(d, k)] if getkey(d, k) in results[build]["gmm"][tool] else float("inf")

    # Loop through tools
    for tool in results[build]["gmm"]:
        # 3D Plot
        pyplot.figure(plot_idx + 1)

        # Get values
        d_vals = numpy.unique(list(map(getd, results[build]["gmm"][tool])))
        k_vals = numpy.unique(list(map(getk, results[build]["gmm"][tool])))
        X = numpy.repeat([d_vals], len(k_vals), 0)
        Y = numpy.repeat([[k] for k in k_vals], len(d_vals), 1)
        Z = numpy.array([[getz(X[i, j], Y[i, j]) for j in range(len(d_vals))] for i in range(len(k_vals))])

        # Plot
        axes.plot_wireframe(X, Y, Z, label=tool, color=numpy.random.random((1, 3)))
        # axes.scatter(X, Y, Z, label=tool, color=numpy.random.random((1, 3)))
        # axes.plot_surface(X, Y, Z, numpy.random.random((1, 4)))

        # 2D plot
        pyplot.figure(plot_idx + 2)

        # Get values
        key_n_vals = {key: getn(key) for key in results[build]["gmm"][tool]}
        n_vals = sorted(key_n_vals.values())
        t_vals = [results[build]["gmm"][tool][key] for key in sorted(key_n_vals.keys(), key=lambda key: key_n_vals[key])]

        # Plot
        pyplot.plot(n_vals, t_vals, marker="x", label=tool)

    # Show 3D legend
    pyplot.figure(plot_idx + 1)
    axes.set_zscale("log")
    pyplot.legend()

    # Show 2D legend, and log-scale axes
    pyplot.figure(plot_idx + 2)
    pyplot.title("GMM ({})".format(build))
    pyplot.xscale("log")
    pyplot.yscale("log")
    pyplot.legend(loc=4, bbox_to_anchor=(1.1, -0.1))

    # PLOT BA GRAPHS

    pyplot.figure(plot_idx + 3)
    pyplot.title("BA ({})".format(build))

    for tool in results[build]["ba"]:
        n_vals = sorted(list(map(lambda key: int(key[2:]), results[build]["ba"][tool].keys())))
        t_vals = list(map(lambda key: results[build]["ba"][tool]["ba" + str(key)], n_vals))
        pyplot.plot(n_vals, t_vals, marker="x", label=tool)

    pyplot.yscale("log")
    pyplot.legend()

    plot_idx += 3


# Display all figures
pyplot.show()
