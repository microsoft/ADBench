import os
import sys
import copy
import json
# import numpy
from matplotlib import pyplot, rcParams
# from mpl_toolkits.mplot3d import Axes3D
import plotly

import utils

rcParams.update({"figure.max_open_warning": 0})

# Script arguments
do_save = "--save" in sys.argv
do_plotly = "--plotly" in sys.argv
do_show = "--show" in sys.argv or not (do_save or do_plotly)

if do_show:
    print("WARNING: `--show` enabled. This script can produce a lot of graphs and you may not wish to display all of them.\n")

# Script constants
figure_size = (9, 6) if do_plotly else (12, 8)
fig_dpi = 96
save_dpi = 144
marker = "x"

# Folders
adbench_dir = os.path.dirname(os.path.realpath(__file__))
ad_root_dir = os.path.dirname(adbench_dir)
in_dir = f"{ad_root_dir}/tmp"
out_dir = f"{ad_root_dir}/Documents/New Figures"
static_out_dir_rel = "/static"
plotly_out_dir_rel = "/plotly"
static_out_dir = f"{out_dir}/{static_out_dir_rel}"
plotly_out_dir = f"{out_dir}/{plotly_out_dir_rel}"

print(f"Output directory is: {out_dir}\n")


# Scan folder for all files, and determine which graphs to create
all_files = [path for path in utils._scandir_rec(in_dir) if "times" in path[-1]]
all_graphs = [path.split("/") for path in list(set(["/".join(path[:-2]) for path in all_files]))]
all_graphs = ([path + ["objective"] for path in all_graphs]
    + [path + ["jacobian"] for path in all_graphs]
    + [path + ["jacobian ÷ objective"] for path in all_graphs])
all_graph_dict = {}

print("Plotting graphs:")

# Loop through each of graphs to be created
figure_idx = 1
for graph in all_graphs:
    # Extract graph variables
    build_type, objective = graph[:2]
    test_size = ", ".join([utils.cap_str(s) for s in graph[2].split("_")]) if len(graph) == 4 else None
    function_type = graph[-1]
    graph_name = f"{objective.upper()}{f' ({test_size})' if test_size is not None else ''} [{function_type.capitalize()}] - {build_type}"
    graph_save_location = f"{build_type}/{function_type}/{graph_name} Graph"
    utils._set_rec(all_graph_dict, [build_type, function_type], graph_name, True)
    print(f"\n  {graph_name}")

    # Create figure
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
    pyplot.ylabel(f"Running time (s) for [{function_type.capitalize()}]")
    pyplot.xscale("log")
    pyplot.yscale("log")

    # Export to plotly (if selected)
    if do_plotly:
        plotly_fig = plotly.tools.mpl_to_plotly(copy.copy(figure))
        plotly_fig["layout"]["showlegend"] = True

        print(f"    Saving plotly: {plotly_out_dir_rel}/{graph_save_location}.html")
        plotly_save_location = f"{plotly_out_dir}/{graph_save_location}.html"
        utils._mkdir_if_none(plotly_save_location)
        plotly.offline.plot(plotly_fig, filename=plotly_save_location, auto_open=False)

    # Add legend (after plotly to avoid error)
    pyplot.legend(loc=4, bbox_to_anchor=(1, 0))

    # Save graph (if selected)
    if do_save:
        print(f"    Saving static: {static_out_dir_rel}/{graph_save_location}.png")
        static_save_location = f"{static_out_dir}/{graph_save_location}.png"
        utils._mkdir_if_none(static_save_location)
        pyplot.savefig(static_save_location, dpi=save_dpi)

    if not do_show:
        pyplot.close(figure)

    # Increment current figure
    figure_idx += 1

print(f"\nPlotted {figure_idx - 1} graphs")

print("\nWriting graphs index...")
index_file = open(f"{out_dir}/graphs_index.json", "w")
index_file.write(json.dumps(all_graph_dict))
index_file.close()

if do_show:
    print("\nDisplaying graphs...\n")
    pyplot.show()


# 3D code (from old method, will need some changes to work)
# TODO fit this in to new method

"""

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

"""
