import os
import sys
import copy
import json
# import numpy
import matplotlib
matplotlib.use('Agg')
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
TIMES_SUBSTRING = "_times_"
CORRECTNESS_SUBSTRING = "_correctness_"

VIOLATION_LABEL = "Wrong calculation result"
ALL_TERMINATED_SUFFIX = " (all crashed/terminated)"

figure_size = (9, 6) if do_plotly else (12, 8)
fig_dpi = 96
save_dpi = 144
colors = ["b", "g", "r", "c", "m", "y"]
markers = ["*", "+", "s", "^"]
all_styles = [(c, m) for m in markers for c in colors]

# Folders
adbench_dir = os.path.dirname(os.path.realpath(__file__))
ad_root_dir = os.path.dirname(adbench_dir)
in_dir = os.path.join(ad_root_dir, "tmp")
out_dir = os.path.join(ad_root_dir, "tmp", "graphs")
static_out_dir_rel = "static"
plotly_out_dir_rel = "plotly"
static_out_dir = os.path.join(out_dir, static_out_dir_rel)
plotly_out_dir = os.path.join(out_dir, plotly_out_dir_rel)

print(f"Output directory is: {out_dir}\n")


# Scan folder for all files, and determine which graphs to create
all_files = [path for path in utils._scandir_rec(in_dir) if TIMES_SUBSTRING in path[-1]]
all_graphs = [path.split("/") for path in set(["/".join(path[:-2]) for path in all_files])]
function_types = ["objective ÷ Manual", "objective", "jacobian", "jacobian ÷ objective"]
all_graphs = [(path, function_type) for function_type in function_types for path in all_graphs]
all_graph_dict = {}


def graph_data(build_type, objective, maybe_test_size):
    '''Creates graph name and graph saving location.'''

    test_size = ", ".join([utils.cap_str(s) for s in maybe_test_size[0].split("_")]) if len(maybe_test_size) == 1 else None
    has_ts = test_size is not None
    graph_name = (f"{objective.upper()}" +
                  (f" ({test_size})" if has_ts else "") +
                  f" [{function_type.capitalize()}] - {build_type}")
    graph_save_location = os.path.join(build_type, function_type, f"{graph_name} Graph")
    utils._set_rec(all_graph_dict, [build_type, function_type, objective.upper()], test_size if has_ts else "", True)
    print(f"\n  {graph_name}")

    return (graph_name, graph_save_location)

has_manual = lambda tool: tool.lower() in ["manual", "manual_eigen"]

def tool_names(graph_files):
    '''Returns a set of tool names from all calculated files.'''

    file_names = map(utils.get_fn, graph_files)
    tool_names_ = set(map(utils.get_tool, file_names))

    # Sort "Manual" to the front
    tool_names_ = sorted(tool_names_, key=lambda x: (not has_manual(x), x))

    print(tool_names_)

    return tool_names_

def read_vals(objective, graph_files, tool):
    '''Extracts data for files of the specified tool.'''

    def get_violations(file_name):
        '''Extracts jacobian calculation correctness.'''

        folder, fn = os.path.split(file_name)
        correctness_file_name = os.path.join(
            in_dir,
            folder,
            fn.replace(TIMES_SUBSTRING, CORRECTNESS_SUBSTRING)
        )

        if not os.path.isfile(correctness_file_name):
            print(f"WARNING: correctness file {correctness_file_name} "
                  "doesn't exist\n")
            return False

        try:
            with open(correctness_file_name, "r", encoding="utf-16") as cf:
                correctness_data = json.load(cf)
                return correctness_data["ViolationsHappened"]
        except Exception as e:
            print(f"WARNING: correctness file {correctness_file_name} parsing "
                  f"failed.\nError message:{e.args}\n")
            return False

    tool_files = [os.path.join(*path) for path in graph_files if utils.get_tool(utils.get_fn(path)) == tool]

    if has_manual(tool):
        violation_vals = [False for file in tool_files]
    else:
        violation_vals = [get_violations(file) for file in tool_files]

    # Extract times
    name_to_n = utils.key_functions[objective]
    info = [(name_to_n(utils.get_test(utils.get_fn(path.split("/")))),
             utils.read_times(os.path.join(in_dir, path)))
            for path in tool_files]

    # Sort values
    info_sorted = sorted(info, key=lambda t: t[0])
    n_vals = list(map(lambda t: t[0], info_sorted))
    t_objective_vals = list(map(lambda t: t[1][0], info_sorted))
    t_jacobian_vals = list(map(lambda t: t[1][1], info_sorted))

    return (n_vals, t_objective_vals, t_jacobian_vals, violation_vals)

def vals_by_tool(objective, graph_files):
    '''Classifies file values by tools'''

    def div_lists(alist, blist):
        return [
            a / b
            if a != float("inf") and b != float("inf")
            else float("inf")
            for a,b in zip(alist,blist)
        ]

    manual_times = None

    for tool in tool_names(graph_files):
        (n_vals, t_objective_vals, t_jacobian_vals, violation) = read_vals(objective, graph_files, tool)

        if manual_times is None and has_manual(tool):
            manual_times = t_objective_vals

        if function_type == 'objective':
            t_vals = t_objective_vals
        elif function_type == 'jacobian':
            t_vals = t_jacobian_vals
        elif function_type == 'objective ÷ Manual':
            if manual_times is None:
                print(f"Hmmm.  Don't have manual_times yet {tool}")
                raise Exception(f"Hmmm.  Don't have manual_times yet {tool}")
            t_vals = div_lists(t_objective_vals, manual_times)
        elif function_type == 'jacobian ÷ objective':
            t_vals = div_lists(t_jacobian_vals, t_objective_vals)
        else:
            raise Exception(f"Unknown function type {function_type}")

        yield (tool, n_vals, t_vals, violation)



if "--help" in sys.argv or "-h" in sys.argv or "-?" in sys.argv:
    ref_msg = f'''
This script produces graphs that visualize benchmark.
CMD arguments:
    --save
            if specified then script saves produced graphs to
            {static_out_dir}

    --plotly
            if specified then script saves graphs in plotly format to
            {plotly_out_dir}

    --show
            if specified then script shows produced graphs on the
            screen. Note, that this is default option if --save or
            --plotly are not defined.

    --help, -h, -?
            show this message
'''
    print(ref_msg)
    sys.exit(0)

# Loop through each of graphs to be created
for (figure_idx, (graph, function_type)) in enumerate(all_graphs, start=1):
    build_type = graph[0]
    objective = graph[1]
    maybe_test_size = graph[2:]

    (graph_name, graph_save_location) = graph_data(build_type, objective, maybe_test_size)

    # Create figure
    figure = pyplot.figure(figure_idx, figsize=figure_size, dpi=fig_dpi)

    # Extract file details
    graph_files = [path for path in all_files if path[:len(graph)] == graph]

    def sorting_key_fun(v):
        y_list = utils.get_non_infinite_y_list(v[2])
        if len(y_list) > 0:
            return sum(y_list) / len(y_list)
        else:
            return 1e9
    sorted_vals_by_tool = sorted(vals_by_tool(objective, graph_files),
                                 key=sorting_key_fun,
                                 reverse=True)

    lines = zip(all_styles, sorted_vals_by_tool)

    handles, labels = [], []
    violation_x, violation_y = [], []
    additional = []
    violation_handle = None

    # Plot results
    for ((color, marker), (tool, n_vals, t_vals, violations)) in lines:
        # Checking neighbours by shifting t_vals requires that
        # it is in the order of monotonic n_vals
        assert n_vals == sorted(n_vals)
        together = list(zip(
            n_vals,
            t_vals,
            [True] + [t_val == float("inf") for t_val in t_vals],
            [t_val == float("inf") for t_val in t_vals[1:]] + [True],
            violations))

        all_terminated = all(t_val == float("inf")
                             for t_val in t_vals)

        label = utils.format_tool(tool)
        # Append label in legend if all point values are infinite
        if all_terminated:
            label += ALL_TERMINATED_SUFFIX

        labels.append(label)
        handles += pyplot.plot(
            n_vals,
            t_vals,
            marker=marker,
            color=color,
            label=label
        )

        additionals = [(n_val, t_val)
                       for (n_val, t_val, missing_left, missing_right, violation)
                       in together
                       if t_val != float("inf")
                       and missing_left
                       and missing_right
                       and violation]

        # addint coordinates of additional markers
        additional.append(([n_val for (n_val, _) in additionals],
                           [t_val for (_, t_val) in additionals],
                           color))
                
        violation_x += [n_val for (n_val, _, _, _, violation)
                        in together if violation]
        violation_y += [t_val for (_, t_val, _, _, violation)
                        in together if violation]

    # if there was calculating violation add violation markers
    if violation_x:
        handles += pyplot.plot(
            violation_x,
            violation_y,
            marker="v",
            mec="k",
            mfc="r",
            ms=8,
            linestyle="None",
            label=VIOLATION_LABEL
        )

        labels.append(VIOLATION_LABEL)

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

        plotly_save_location_view = os.path.join(plotly_out_dir_rel, f"{graph_save_location}.html")
        plotly_save_location = os.path.join(plotly_out_dir, f"{graph_save_location}.html")

        print(f"    Saving plotly: {plotly_save_location_view}")
        utils._mkdir_if_none(plotly_save_location)
        plotly.offline.plot(plotly_fig, filename=plotly_save_location, auto_open=False)

    # Add legend (after plotly to avoid error)
    pyplot.legend(handles, labels, loc=4, bbox_to_anchor=(1, 0))

    # draw additional markers
    # Note: we do this later than plotly converting because plotly doesn't
    #       need additional markers
    for x, y, color in additional:
        pyplot.plot(
            x,
            y,
            linestyle="None",
            marker="_",
            ms=17,
            mew=2,
            color=color,
            zorder=0
        )

    # Save graph (if selected)
    if do_save:
        static_save_location_view = os.path.join(
            static_out_dir_rel,
            f"{graph_save_location}.png"
        )

        static_save_location = os.path.join(static_out_dir, f"{graph_save_location}.png")

        print(f"    Saving static: {static_save_location_view}")
        utils._mkdir_if_none(static_save_location)
        pyplot.savefig(static_save_location, dpi=save_dpi)

    if not do_show:
        pyplot.close(figure)

print(f"\nPlotted {figure_idx} graphs")

print("\nWriting graphs index...")
index_file = open(os.path.join(out_dir, "graphs_index.json"), "w")
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
