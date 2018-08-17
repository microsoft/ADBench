
project("MuPad")

message("Building mex files")

set(AWFUL_MATLAB "${CMAKE_SOURCE_DIR}/submodules/awful/matlab/")

foreach (D_VAL ${GMM_D_VALS})
	foreach (K_VAL ${GMM_K_VALS})
		execute_process(COMMAND "${CMAKE_CURRENT_LIST_DIR}/mex.bat" "${CMAKE_CURRENT_LIST_DIR}" "${CMAKE_CURRENT_BINARY_DIR}" "${AWFUL_MATLAB}" "${D_VAL}" "${K_VAL}")
	endforeach(K_VAL)
endforeach(D_VAL)



message("Finished building mex files")
