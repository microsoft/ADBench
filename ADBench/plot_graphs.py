# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import os
import sys
import copy
import json
from collections import namedtuple
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
do_help = any(help in sys.argv for help in ["--help", "-h", "-?"])
do_show = "--show" in sys.argv or not (do_save or do_plotly or do_help)

# Script constants
TIMES_SUBSTRING = "_times_"
CORRECTNESS_SUBSTRING = "_correctness_"

VIOLATION_LABEL = "Wrong calculation result"
ALL_TERMINATED_SUFFIX = " (all crashed/timed out)"

figure_size = (9, 6) if do_plotly else (12, 8)
fig_dpi = 96
save_dpi = 144

# for tools that have no mapped style
default_styles = [ (color, "x") for color in "rgbcmyk" ]
tool_styles = {
    # C++ tools
    "Finite": ("b", "o", "C++, Finite"),
    "FiniteEigen": ("b", "s", "C++, Finite Eigen"),
    "Manual": ("k", "o", "C++, Manual"),
    "ManualEigen": ("k", "s", "C++, Manual Eigen"),
    "ManualEigenVector": ("k", "D", "C++, Manual Eigen Vector"),
    "Tapenade": ("y", "*", "C, Tapenade"),

    # .Net tools
    "DiffSharpModule": ("grey", "D", "F#, DiffSharp"),

    # Python tools
    "PyTorch": ("g", "s", "Python, PyTorch"),
    "Tensorflow": ("r", "s", "Python, Tensorflow (2.0, eager)"),
    "TensorflowGraph": ("purple", "s", "Python, Tensorflow (2.0, graph)"),
    "Autograd": ("c", "s", "Python, Autograd"),
    "Autograd_split": ("grey", "*", "Python, Autograd (Split)"),

    # Julia tools
    "Julia": ("c", "v", "Julia, Julia"),
    "Zygote": ("y", "v", "Julia, Zygote")
}

# Folders
adbench_dir = os.path.dirname(os.path.realpath(__file__))
ad_root_dir = os.path.dirname(adbench_dir)
in_dir = os.path.join(ad_root_dir, "tmp")
out_dir = os.path.join(in_dir, "graphs")
static_out_dir_rel = "static"
plotly_out_dir_rel = "plotly"
static_out_dir = os.path.join(out_dir, static_out_dir_rel)
plotly_out_dir = os.path.join(out_dir, plotly_out_dir_rel)

# Scan folder for all files, and determine which graphs to create
all_files = [path for path in utils._scandir_rec(in_dir) if TIMES_SUBSTRING in path[-1]]
all_graphs = [path.split("/") for path in set(["/".join(path[:-2]) for path in all_files])]
function_types = ["objective ÷ Manual", "objective", "jacobian", "jacobian ÷ objective"]
all_graphs = [(path, function_type) for function_type in function_types for path in all_graphs]
all_graph_dict = {}


def graph_data(build_type, objective, maybe_test_size, function_type):
    '''Creates graph name and graph saving location.'''

    test_size = ", ".join([utils.cap_str(s) for s in maybe_test_size.split("_")]) if len(maybe_test_size) > 0 else None
    has_ts = test_size is not None
    graph_name = (f"{objective_display_name(objective)}" +
                  (f" ({test_size})" if has_ts else "") +
                  f" [{function_type.capitalize()}] - {build_type}")
    graph_save_location = os.path.join(build_type, function_type, f"{graph_name} Graph")
    utils._set_rec(all_graph_dict, [build_type, function_type, objective.upper()], test_size if has_ts else "", True)
    print(f"\n  {graph_name}")

    return (graph_name, graph_save_location)

# What we call LSTM is not quite a full LSTM.  Rather it's an LSTM
# with diagonal weight matrices.  We don't want to be misleading so we
# rename the graph.  Eventually we will implement a full LSTM and we
# will remove this special case.  See
#
#     https://github.com/awf/ADBench/issues/143
def objective_display_name(objective):
    if objective.upper() == "LSTM":
        return "D-LSTM"
    else:
        return objective.upper()

has_manual = lambda tool: tool.lower() in ["manual", "manual_eigen"]

def tool_names(graph_files):
    '''Returns a set of tool names from all calculated files.'''

    tool_names_ = set(map(utils.get_tool_from_path, graph_files))

    # Sort "Manual" to the front
    tool_names_ = sorted(tool_names_, key=lambda x: (not has_manual(x), x))
    
    print(f"    Tools: {tool_names_}\n")

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
            with open(correctness_file_name, "r", encoding="ascii") as cf:
                correctness_data = json.load(cf)
                return correctness_data["ViolationsHappened"]
        except Exception as e:
            print(f"WARNING: correctness file {correctness_file_name} parsing "
                  f"failed.\nError message:{e.args}\n")
            return False

    tool_files = [os.path.join(*path) for path in graph_files if utils.get_tool_from_path(path) == tool]

    if has_manual(tool):
        violation_info = [False for file in tool_files]
    else:
        violation_info = [get_violations(file) for file in tool_files]

    # Extract times
    name_to_n = utils.key_functions[objective]
    info = [(name_to_n(utils.get_test(utils.get_fn(path.split("/")))),
             utils.read_times(os.path.join(in_dir, path)),
             violation)
            for (path, violation) in zip(tool_files, violation_info)]

    # Sort values
    info_sorted = sorted(info, key=lambda t: t[0])
    n_vals = list(map(lambda t: t[0], info_sorted))
    t_objective_vals = list(map(lambda t: t[1][0], info_sorted))
    t_jacobian_vals = list(map(lambda t: t[1][1], info_sorted))
    violation_vals = list(map(lambda t: t[2], info_sorted))

    return (n_vals, t_objective_vals, t_jacobian_vals, violation_vals)

def vals_by_tool(objective, graph_files, function_type):
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

def draw_vertical_lines(vals_by_tool):
    '''Adds vertical lines to the figure for clarifying results.'''

    all_n_vals = set.union(*(set(n_vals) for _, n_vals, _, _ in vals_by_tool))

    for n in all_n_vals:
        pyplot.axvline(n, ls = '-', color = "lightgrey", zorder = 0.0, lw = 0.5)

def print_messages():
    '''Prints messages and exits the program if --help were specified'''

    if do_help:
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

    if do_show:
        print("WARNING: `--show` enabled. This script can produce a lot of "
              "graphs and you may not wish to display all of them.\n")

    if do_save or do_plotly:
        print(f"Output directory is: {out_dir}\n")

def get_sorted_vals_by_tool(objective, graph, function_type):
    # Extract file details
    graph_files = [path for path in all_files if path[:len(graph)] == graph]

    def sorting_key_fun(v):
        y_list = utils.get_non_infinite_y_list(v[2])
        if len(y_list) > 0:
            return sum(y_list) / len(y_list)
        else:
            return 1e9
    sorted_vals_by_tool = sorted(vals_by_tool(objective, graph_files, function_type),
                                 key=sorting_key_fun,
                                 reverse=True)

    return sorted_vals_by_tool

def vals_with_neighbours_and_violation(n_vals, t_vals, violations):
    '''Returns an iterator of tuples of the form

(n_val, t_val, left_neighbour_missing, right_neighbour_missing, was_violition)
'''

    # Checking neighbours by shifting t_vals requires that
    # it is in the order of monotonic n_vals
    assert n_vals == sorted(n_vals)
    return zip(
        n_vals,
        t_vals,
        # Whether the left neighbour is missing
        [True] + [t_val == float("inf") for t_val in t_vals],
        # Whether the right neighbour is missing
        [t_val == float("inf") for t_val in t_vals[1:]] + [True],
        violations)

def together_and_additionals(n_vals, t_vals, violations):
    '''Returns (together, additionals)

where together is the list of tuples returned by vals_with_neighbours_and_violation
and additionals is a list of points that were violations, not infinite, and had
both neighbours missing'''

    together = list(vals_with_neighbours_and_violation(n_vals, t_vals, violations))
    additionals = [(n_val, t_val)
                   for (n_val, t_val, missing_left, missing_right, violation)
                   in together
                   if t_val != float("inf")
                   and missing_left
                   and missing_right
                   and violation]

    return (together, additionals)

def label_and_handle(tool, n_vals, t_vals, style, disp_name):
    '''Returns (label, handle)

where label is the label that should be used in the legend for this
tool and handle is a handle to the plotted data for this tool'''

    color, marker = style
    all_terminated = all(t_val == float("inf") for t_val in t_vals)

    # Append label in legend if all point values are infinite
    if all_terminated:
        disp_name += ALL_TERMINATED_SUFFIX

    handle = pyplot.plot(
        n_vals,
        t_vals,
        marker=marker,
        color=color,
        label=disp_name
    )

    return (disp_name, handle)

def values_and_styles(sorted_vals_by_tool):
    '''Returns generator for tool values concatenated with tool style and
    display name: (values, style, display_name).'''

    next_default = 0
    for item in sorted_vals_by_tool:
        tool = item[0]
        if tool in tool_styles:
            style = tool_styles[tool]
        else:
            style = default_styles[next_default]
            next_default = (next_default + 1) % len(default_styles)
            print(f'WARNING: style is not specified for tool "{tool}"! One of default styles is used')

        display_name = utils.format_tool(tool) if len(style) == 2 else style[2]

        yield item, style[0: 2], display_name

def generate_graph(figure_info, sorted_vals_by_tool):
    '''Generates the graph for the given figure.
    
    Args:
        figure_info (named tuple): information of the figure.
            idx: index of the figure.
            build_type: the type of the tool build.
            objective: the name of the objective, the graph is plotted.
            maybe_test_size: test size or empty string if the test can not have
                a size.
            function_type: type of the current graph (e.g. "Jacobian",
                "Objective" etc.)
        sorted_vals_by_tool: values for plotting, sorted by tool name.
    '''

    # Create figure
    figure = pyplot.figure(figure_info.idx, figsize=figure_size, dpi=fig_dpi)

    handles, labels = [], []
    non_timeout_violation_x, non_timeout_violation_y = [], []
    additional = []

    # Plot results
    for ((tool, n_vals, t_vals, violations), style, disp_name) in values_and_styles(sorted_vals_by_tool):
        (label, handle) = label_and_handle(tool, n_vals, t_vals, style, disp_name)
        (together, additionals) = together_and_additionals(n_vals, t_vals, violations)

        labels.append(label)
        handles += handle

        # adding coordinates of additional markers
        additional.append(([n_val for (n_val, _) in additionals],
                           [t_val for (_, t_val) in additionals],
                           style[0]))

        non_timeout_violation_x += [n_val for (n_val, t_val, _, _, violation)
                        in together if violation and t_val != float("inf")]
        non_timeout_violation_y += [t_val for (_, t_val, _, _, violation)
                        in together if violation and t_val != float("inf")]


    # if there was calculating violation add violation markers
    #
    # We must create the plot only if there was a violation because
    # plotly will add the violation marker to its legend even if
    # non_timeout_violation_x/y are empty.
    if len(non_timeout_violation_x) > 0:
        handles += pyplot.plot(
            non_timeout_violation_x,
            non_timeout_violation_y,
            marker="v",
            mec="k",
            mfc="r",
            ms=8,
            linestyle="None",
            label=VIOLATION_LABEL
        )

        labels.append(VIOLATION_LABEL)

    (graph_name, graph_save_location) = graph_data(figure_info.build_type, figure_info.objective,
        figure_info.maybe_test_size, figure_info.function_type)

    # Setup graph attributes
    xlabel = "No. independent variables"
    if "hand" == figure_info.objective or "hand" in figure_info.maybe_test_size:
        xlabel = "No. correspondencies"
        
    pyplot.title(graph_name)
    pyplot.xlabel(xlabel)
    pyplot.ylabel(f"Running time (s) for [{figure_info.function_type.capitalize()}]")
    pyplot.xscale("log")
    pyplot.yscale("log")

    draw_vertical_lines(sorted_vals_by_tool)

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

def get_plot_data(all_graphs):
    '''Creates a plot data from the files, produced by the global runner.'''

    plot_data = []

    for graph_info in all_graphs:
        (graph, function_type) = graph_info
        build_type = graph[0]
        objective = graph[1]
        maybe_test_size = graph[2] if len(graph) == 3 else ""

        print(f"\n    Build type: {build_type}\n"
              f"    Function type: {function_type}\n"
              f"    Objective: {objective}\n"
              f"    Test size: {maybe_test_size}")
        sorted_vals_by_tool = get_sorted_vals_by_tool(objective, graph, function_type)

        plot_data.append({
            "build": build_type,
            "objective": objective,
            "function_type": function_type,
            "test_size": maybe_test_size,
            "values": [
                {
                    "tool": tool_name,
                    "time": time_vals,
                    "variable_count": var_count_vals,
                    "violations": violation_vals
                }
                for tool_name, var_count_vals, time_vals, violation_vals in sorted_vals_by_tool
            ]
        })

    return plot_data

def extract_vals_and_figure_info_from_plot_data(data):
    '''Extracts vals sorted by the tool and the figure info from the plot
    data for the single figure.'''

    sorted_vals_by_tool = [
        (val["tool"], val["variable_count"], val["time"], val["violations"])
        for val in data["values"]
    ]

    figure_info = namedtuple(
        "figure_info",
        "idx, build_type, objective, maybe_test_size, function_type"
    )

    figure_info.build_type = data["build"]
    figure_info.objective = data["objective"]
    figure_info.maybe_test_size = data["test_size"]
    figure_info.function_type = data["function_type"]

    return sorted_vals_by_tool, figure_info

def main():
    print_messages()

    print("\nGetting plot data...\n")
    plot_data = get_plot_data(all_graphs)

    # Loop through each of graphs to be created
    print("\nGenerating graphs...\n")
    for (figure_idx, data) in enumerate(plot_data, start=1):
        sorted_vals_by_tool, figure_info = extract_vals_and_figure_info_from_plot_data(data)
        figure_info.idx = figure_idx
        generate_graph(figure_info, sorted_vals_by_tool)

    print(f"\nPlotted {figure_idx} graphs")

    print("\nWriting graphs index...")
    with open(os.path.join(out_dir, "graphs_index.json"), "w") as index_file:
        index_file.write(json.dumps(all_graph_dict))

    print("\nWriting plot data...")
    with open(os.path.join(out_dir, "plot_data.json"), "w") as plot_data_file:
        plot_data_file.write(json.dumps(plot_data))

    if do_show:
        print("\nDisplaying graphs...\n")
        pyplot.show()

if __name__ == '__main__': main()
