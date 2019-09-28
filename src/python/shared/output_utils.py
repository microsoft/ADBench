import numpy as np

PRECISION = 8   # in signs after dot

def objective_file_name(output_prefix, input_basename, module_basename):
    return output_prefix + input_basename + "_F_" + module_basename + ".txt"

def jacobian_file_name(output_prefix, input_basename, module_basename):
    return output_prefix + input_basename + "_J_" + module_basename + ".txt"

def save_time_to_file(filepath, objective_time, derivative_time):
    # open file in write mode or create new one if it does not exist
    out = open(filepath,"w")
    out.write(np.format_float_scientific(objective_time, unique=False, precision=PRECISION) + \
        '\n' + np.format_float_scientific(derivative_time, unique=False, precision=PRECISION))
    out.close()

def save_value_to_file(filepath, value):
    out = open(filepath,"w")
    out.write(np.format_float_scientific(value, unique=False, precision=PRECISION))
    out.close()

def save_vector_to_file(filepath, gradient):
    out = open(filepath,"w")

    for value in gradient:
        out.write(np.format_float_scientific(value, unique=False, precision=PRECISION) + '\n')

    out.close()

def save_jacobian_to_file(filepath, jacobian):
    jacobian_nrows = jacobian.shape[0]
    jacobian_ncols = jacobian.shape[1]

    out = open(filepath,"w")

    # output row-major matrix
    for i in range(jacobian_nrows):
        out.write(np.format_float_scientific(jacobian[i, 0], unique=False, precision=PRECISION))
        for j in range(1, jacobian_ncols):
            out.write('\t' + np.format_float_scientific(jacobian[i, j], unique=False, precision=PRECISION))
        out.write('\n')

    out.close()

def save_errors_to_file(filepath, reprojection_error, zach_weight_error):
    out = open(filepath,"w")

    out.write("Reprojection error:\n")
    for value in reprojection_error:
        out.write(np.format_float_scientific(value, unique=False, precision=PRECISION) + '\n')

    out.write("Zach weight error:\n")
    for value in zach_weight_error:
        out.write(np.format_float_scientific(value, unique=False, precision=PRECISION) + '\n')

    out.close()

def save_sparse_j_to_file(filepath, J):
    rows = len(J.rows)
    cols = len(J.cols)

    out = open(filepath,"w")

    out.write(str(J.nrows) + ' ' + str(J.ncols) + '\n')

    out.write(str(rows) + '\n')
    for i in range(rows):
        out.write(str(J.rows[i]) + ' ')
    out.write('\n')
    
    out.write(str(cols) + '\n')
    for i in range(cols):
        out.write(str(J.cols[i]) + ' ')
    out.write('\n')

    for i in range(len(J.vals)):
        out.write(np.format_float_scientific(J.vals[i], unique=False, precision=PRECISION) + ' ')

    out.close()