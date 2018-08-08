
project("Tools-Ceres")

# Get Ceres (with GLOG)
hunter_add_package(ceres-solver)
find_package(Ceres CONFIG REQUIRED)
include_directories("${CERES_INCLUDE_DIRS}")

# Create GMM with different #define D and K values
set(D_VALS 2 10) # NOTE unable to run 20, 32 due to memory error
set(K_VALS 5 10 25 50) # removed 100, 200 as well
# NOTE may be able to run more than is done here
foreach (D_VAL ${D_VALS})
	foreach (K_VAL ${K_VALS})
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
