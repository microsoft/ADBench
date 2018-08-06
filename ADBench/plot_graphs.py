import os
from matplotlib import pylab, pyplot
from mpl_toolkits.mplot3d import Axes3D

tmp_dir = "../tmp/"

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
for tool in os.listdir(tmp_dir + "gmm"):
    for filename in os.listdir(tmp_dir + "gmm/" + tool):
        fn_split = filename.split(".")[0].split("_")
        if fn_split[3] != "times":
            continue

        d = int(fn_split[1][1:])
        k = int(fn_split[2][1:])

        file = open(tmp_dir + "gmm/" + tool + "/" + filename)
        contents = file.read()
        file.close()

        time = float(contents.split(" ")[0])

        _set_rec(results, ["gmm", tool, d, k], time)


# Create axes
figure = pyplot.figure()
axes = figure.add_subplot(111, projection="3d")

# Label axes
axes.set_xlabel("D values")
axes.set_ylabel("K values")
axes.set_zlabel("Time taken")

# Loop through tools
for tool in results["gmm"]:
    # Sort values into single lists
    d_vals = []
    k_vals = []
    t_vals = []
    for d in sorted(results["gmm"][tool].keys()):
        for k in sorted(results["gmm"][tool][d].keys()):
            d_vals.append(d)
            k_vals.append(k)
            t_vals.append(results["gmm"][tool][d][k])

    # Plot values
    axes.plot(d_vals, k_vals, t_vals, label=tool)

# Show legend
pyplot.legend()
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
