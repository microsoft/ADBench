
project("MuPad")

message("Building mex files")

set(AWFUL_MATLAB "${CMAKE_SOURCE_DIR}/submodules/awful/matlab/")

# Build GMM mex files
foreach (D_VAL ${GMM_D_VALS})
	foreach (K_VAL ${GMM_K_VALS})
		execute_process(COMMAND "${CMAKE_CURRENT_LIST_DIR}/mex.bat" "${CMAKE_CURRENT_LIST_DIR}/example_gmm_objective_mex_d${D_VAL}_K${K_VAL}.cxx" "${CMAKE_CURRENT_BINARY_DIR}" "${AWFUL_MATLAB}")
	endforeach(K_VAL)
endforeach(D_VAL)

# Build BA mex files
execute_process(COMMAND "${CMAKE_CURRENT_LIST_DIR}/mex.bat" "${CMAKE_CURRENT_LIST_DIR}/mupad_ba_compute_reproj_err_mex.cxx" "${CMAKE_CURRENT_BINARY_DIR}" "${AWFUL_MATLAB}")
execute_process(COMMAND "${CMAKE_CURRENT_LIST_DIR}/mex.bat" "${CMAKE_CURRENT_LIST_DIR}/mupad_ba_compute_weight_err_mex.cxx" "${CMAKE_CURRENT_BINARY_DIR}" "${AWFUL_MATLAB}")

message("Finished building mex files")
