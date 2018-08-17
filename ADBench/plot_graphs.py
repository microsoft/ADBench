import os
import sys
import numpy
from matplotlib import pylab, pyplot
from mpl_toolkits.mplot3d import Axes3D
import plotly

tmp_dir = "../tmp"
out_dir = "../Documents/New Figures"
do_save = "--save" in sys.argv
do_plotly = "--plotly" in sys.argv

figure_size = (9, 6) if do_plotly else (12, 8)

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

    # Create 3D axes
    figure = pyplot.figure(plot_idx + 1, figsize=figure_size, dpi=96)
    pyplot.subplots_adjust(left=0.05, right=0.95, top=0.95, bottom=0.05)
    axes = figure.add_subplot(111, projection="3d")

    # Loop through tools
    for tool in results[build]["gmm"]:
        # 3D Plot
        pyplot.figure(plot_idx + 1, figsize=figure_size, dpi=96)

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
        pyplot.figure(plot_idx + 2, figsize=figure_size, dpi=96)

        # Get values
        key_n_vals = {key: getn(key) for key in results[build]["gmm"][tool]}
        n_vals = sorted(key_n_vals.values())
        t_vals = [results[build]["gmm"][tool][key] for key in sorted(key_n_vals.keys(), key=lambda key: key_n_vals[key])]

        # Plot
        pyplot.plot(n_vals, t_vals, marker="x", label=tool)

    # Setup 3d figure
    pyplot.figure(plot_idx + 1, figsize=figure_size, dpi=96)
    pyplot.title("GMM ({})".format(build))
    pyplot.subplots_adjust(left=0.05, right=0.95, top=0.95, bottom=0.05)
    axes.set_xlabel("D values")
    axes.set_ylabel("K values")
    axes.set_zlabel("Time taken")
    axes.set_zscale("log")
    pyplot.legend()

    # Setup 2D figure
    figure = pyplot.figure(plot_idx + 2, figsize=figure_size, dpi=96)
    pyplot.title("GMM ({})".format(build))
    pyplot.subplots_adjust(left=0.08, right=0.95, top=0.93, bottom=0.1)
    pyplot.xlabel("Input size [d * (d - 1) / 2 * k]")
    pyplot.ylabel("Running time (s)")
    pyplot.xscale("log")
    pyplot.yscale("log")

    if do_plotly:
        plotly_fig = plotly.tools.mpl_to_plotly(figure)
        plotly_fig["layout"]["showlegend"] = True
        plotly.offline.plot(plotly_fig, filename="{}/plotly/GMM ({}) Graph.html".format(out_dir, build), auto_open=False)
    else:
        pyplot.legend(loc=2, bbox_to_anchor=(0, 1))

        if do_save:
            pyplot.savefig("{}/GMM ({}) Graph.png".format(out_dir, build), dpi=144)

    # PLOT BA GRAPHS

    # Set up figure
    figure = pyplot.figure(plot_idx + 3, figsize=figure_size, dpi=96)
    pyplot.title("BA ({})".format(build))
    pyplot.subplots_adjust(left=0.08, right=0.95, top=0.93, bottom=0.1)
    pyplot.xlabel("Input size")
    pyplot.ylabel("Running time (s)")

    # Loop through tools and plot results
    for tool in results[build]["ba"]:
        n_vals = sorted(list(map(lambda key: int(key[2:]), results[build]["ba"][tool].keys())))
        t_vals = list(map(lambda key: results[build]["ba"][tool]["ba" + str(key)], n_vals))
        pyplot.plot(n_vals, t_vals, marker="x", label=tool)

    pyplot.yscale("log")

    if do_plotly:
        plotly_fig = plotly.tools.mpl_to_plotly(figure)
        plotly_fig["layout"]["showlegend"] = True
        plotly.offline.plot(plotly_fig, filename="{}/plotly/BA ({}) Graph.html".format(out_dir, build), auto_open=False)
    else:
        pyplot.legend(loc=2, bbox_to_anchor=(0, 1))

        if do_save:
            pyplot.savefig("{}/BA ({}) Graph.png".format(out_dir, build), dpi=144)

    plot_idx += 3


# Display all figures
if not do_save and not do_plotly:
    pyplot.show()
