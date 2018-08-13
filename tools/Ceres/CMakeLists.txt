
project("Tools-Ceres")

# Get Ceres (with GLOG)
hunter_add_package(ceres-solver)
find_package(Ceres CONFIG REQUIRED)
include_directories("${CERES_INCLUDE_DIRS}")

# Create GMM with different #define D and K values
foreach (D_VAL ${GMM_D_VALS})
	foreach (K_VAL ${GMM_K_VALS})
		add_executable("Tools-Ceres-GMM-d${D_VAL}-K${K_VAL}" "main.cpp" "${CERES-SOLVER_ROOT}/include/ceres/ceres.h")
		target_compile_definitions("Tools-Ceres-GMM-d${D_VAL}-K${K_VAL}" PUBLIC "DO_GMM" GMM_D=${D_VAL} GMM_K=${K_VAL})
		target_link_libraries("Tools-Ceres-GMM-d${D_VAL}-K${K_VAL}" "${CERES-SOLVER_ROOT}/lib/ceres-debug.lib" "${CERES-SOLVER_ROOT}/lib/glogd.lib")
	endforeach(K_VAL)
endforeach(D_VAL)

# Create BA
add_executable("Tools-Ceres-BA" "main.cpp" "${CERES-SOLVER_ROOT}/include/ceres/ceres.h")
target_compile_definitions("Tools-Ceres-BA" PUBLIC "DO_BA")
target_link_libraries("Tools-Ceres-BA" "${CERES-SOLVER_ROOT}/lib/ceres-debug.lib" "${CERES-SOLVER_ROOT}/lib/glogd.lib")

# Copy GLOG DLL
file(COPY "${CERES-SOLVER_ROOT}/bin/glogd.dll" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")

# NOTE GMM seems to need old libglog.lib, but BA seems to need new glogd.lib
