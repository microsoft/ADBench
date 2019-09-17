import numpy as np

def objective_file_name(output_prefix, input_basename, module_basename):
    return output_prefix + input_basename + "_F_" + module_basename + ".txt"

def jacobian_file_name(output_prefix, input_basename, module_basename):
    return output_prefix + input_basename + "_J_" + module_basename + ".txt"

def save_time_to_file(filepath, objective_time, derivative_time):
    # open file in write mode or create new one if it does not exist
    out = open(filepath,"w")
    out.write(np.format_float_scientific(objective_time, unique=False, precision=6) + '\n' + np.format_float_scientific(derivative_time, unique=False, precision=6))
    out.close()

def save_value_to_file(filepath, value):
    out = open(filepath,"w")
    out.write(np.format_float_scientific(value, unique=False, precision=6))
    out.close()

def save_vector_to_file(filepath, gradient):
    out = open(filepath,"w")

    for value in gradient:
        out.write(np.format_float_scientific(value, unique=False, precision=6) + '\n')

    out.close()

def save_jacobian_to_file(filepath, jacobian, jacobian_ncols, jacobian_nrows):
    out = open(filepath,"w")

    for i in range(jacobian_nrows):
        out.write(np.format_float_scientific(jacobian[i], unique=False, precision=6))
        for j in range(1, jacobian_ncols):
            out.write('\t' + np.format_float_scientific(jacobian[jacobian_nrows * j + i], unique=False, precision=6))
        out.write('\n')

    out.close()

def save_errors_to_file(filepath, reprojection_error, zach_weight_error):
    out = open(filepath,"w")

    out.write("Reprojection error:\n")
    for value in reprojection_error:
        out.write(np.format_float_scientific(value, unique=False, precision=6) + '\n')

    out.write("Zach weight error:\n")
    for value in zach_weight_error:
        out.write(np.format_float_scientific(value, unique=False, precision=6) + '\n')

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

    for i in range(len(J.vals)):
        out.write(str(J.vals[i]) + ' ')

    out.close()