import os
import sys
import copy
# import numpy
from matplotlib import pyplot
# from mpl_toolkits.mplot3d import Axes3D
import plotly

import utils


# Script arguments
do_save = "--save" in sys.argv
do_plotly = "--plotly" in sys.argv
do_show = "--show" in sys.argv or not (do_save or do_plotly)

# Script constants
figure_size = (9, 6) if do_plotly else (12, 8)
fig_dpi = 96
save_dpi = 144
marker = "x"

# Folders
adbench_dir = os.path.dirname(os.path.realpath(__file__))
ad_root_dir = os.path.dirname(adbench_dir)
in_dir = "{}/tmp".format(ad_root_dir)
out_dir = "{}/Documents/New Figures".format(ad_root_dir)
plotly_out_dir = "{}/plotly".format(out_dir)
if not os.path.isdir(out_dir):
    os.makedirs(out_dir)
if not os.path.isdir(plotly_out_dir):
    os.makedirs(plotly_out_dir)


# Scan folder for all files, and determine which graphs to create
all_files = [path for path in utils._scandir_rec(in_dir) if "times" in path[-1]]
all_graphs = [path.split("/") for path in list(set(["/".join(path[:-2]) for path in all_files]))]
all_graphs = [path + ["objective"] for path in all_graphs] + [path + ["jacobian"] for path in all_graphs]

# Loop through each of graphs to be created
figure_idx = 1
for graph in all_graphs:
    # Extract graph variables
    build_type, objective = graph[:2]
    test_size = graph[2] if len(graph) == 4 else None
    function_type = graph[-1]
    graph_name = "{}{} {} - {}".format(objective.upper(), " ({})".format(test_size) if test_size is not None else "", function_type.capitalize(), build_type)
    print("Plotting:", graph_name)

    # Select figure
    figure = pyplot.figure(figure_idx, figsize=figure_size, dpi=fig_dpi)

    # Extract file details
    graph_files = [path for path in all_files if path[:len(graph) - 1] == graph[:-1]]
    file_names = list(map(utils.get_fn, graph_files))
    tool_names = list(set(map(utils.get_tool, file_names)))
    tool_files = {tool: ["/".join(path) for path in graph_files if utils.get_tool(utils.get_fn(path)) == tool] for tool in tool_names}

    # Loop through tools
    for tool in tool_names:
        # Extract times
        times_dict = {utils.get_test(utils.get_fn(path.split("/"))): utils.read_time(in_dir + "/" + path, function_type) for path in tool_files[tool]}
        time_pairs = [(key, times_dict[key]) for key in times_dict]

        # Sort values
        times_sorted = sorted(time_pairs, key=lambda pair: utils.key_functions[objective](pair[0]))
        n_vals = list(map(lambda pair: utils.key_functions[objective](pair[0]), times_sorted))
        t_vals = list(map(lambda pair: pair[1], times_sorted))

        # Plot results
        pyplot.plot(n_vals, t_vals, label=utils.format_tool(tool), marker=marker)

    # Setup graph attributes
    pyplot.title(graph_name)
    pyplot.xlabel("No. independent variables")
    pyplot.ylabel("Running time (s) for {}".format(function_type))
    pyplot.xscale("log")
    pyplot.yscale("log")

    # Export to plotly (if selected)
    if do_plotly:
        plotly_fig = plotly.tools.mpl_to_plotly(copy.copy(figure))
        plotly_fig["layout"]["showlegend"] = True
        plotly.offline.plot(plotly_fig, filename="{}/{} Graph.html".format(plotly_out_dir, graph_name), auto_open=False)

    # Add legend (after plotly to avoid error)
    pyplot.legend(loc=4, bbox_to_anchor=(1, 0))

    # Save graph (if selected)
    if do_save:
        pyplot.savefig("{}/{} Graph.png".format(out_dir, graph_name), dpi=save_dpi)

    # Increment current figure
    figure_idx += 1

if do_show:
    pyplot.show()


# Old method
# NOTE - keeping for the 3D code

"""

results_f = {"type": "tf"}
results_J = {"type": "tJ"}
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

                times = contents.replace("\n", " ").split(" ")
                tf = float(times[0])
                tJ = float(times[1])

                _set_rec(results_f, [build, test, tool_name, name], tf)
                _set_rec(results_J, [build, test, tool_name, name], tJ)


exit()

plot_idx = 0
for results in [results_f, results_J]:
    func_name = "autodiff" if results["type"] == "tJ" else "objective"
    out_dir = "{}/{}".format(root_out_dir, func_name)

    if not os.path.isdir("{}/{}".format(out_dir, "plotly")):
        os.makedirs("{}/{}".format(out_dir, "plotly"))

    for build in results:
        if build == "type":
            continue

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
        pyplot.title("GMM ({}) - {}".format(build, func_name))
        pyplot.subplots_adjust(left=0.05, right=0.95, top=0.95, bottom=0.05)
        axes.set_xlabel("D values")
        axes.set_ylabel("K values")
        axes.set_zlabel("Time taken")
        axes.set_zscale("log")
        pyplot.legend()

        # Setup 2D figure
        figure = pyplot.figure(plot_idx + 2, figsize=figure_size, dpi=96)
        pyplot.title("GMM ({}) - {}".format(build, func_name))
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
        pyplot.title("BA ({}) - {}".format(build, func_name))
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

"""
