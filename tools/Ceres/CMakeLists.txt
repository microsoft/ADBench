
project("Tools-Ceres")

# Get Ceres (with GLOG)
hunter_add_package(ceres-solver)
find_package(Ceres CONFIG REQUIRED)
include_directories("${CERES_INCLUDE_DIRS}")

# Select Debug or Release lib path
if (${CMAKE_BUILD_TYPE} MATCHES "Debug")
	set(CERES_LIB "${CERES-SOLVER_ROOT}/lib/ceres-debug.lib")
	set(GLOG_LIB "${CERES-SOLVER_ROOT}/lib/glogd.lib")
	set(GLOG_DLL "${CERES-SOLVER_ROOT}/bin/glogd.dll")
else ()
	set(CERES_LIB "${CERES-SOLVER_ROOT}/lib/ceres.lib")
	set(GLOG_LIB "${CERES-SOLVER_ROOT}/lib/glog.lib")
	set(GLOG_DLL "${CERES-SOLVER_ROOT}/bin/glog.dll")
endif ()

function(build_ceres EXE_NAME)
	add_executable("Tools-Ceres-${EXE_NAME}" "main.cpp" "${CERES-SOLVER_ROOT}/include/ceres/ceres.h")
	target_compile_definitions("Tools-Ceres-${EXE_NAME}" PUBLIC ${ARGN})
	target_link_libraries("Tools-Ceres-${EXE_NAME}" ${CERES_LIB} ${GLOG_LIB})
endfunction(build_ceres)

# Create GMM with different #define D and K values
foreach (D_VAL ${GMM_D_VALS})
	foreach (K_VAL ${GMM_K_VALS})
		build_ceres("GMM-d${D_VAL}-K${K_VAL}" "DO_GMM" GMM_D=${D_VAL} GMM_K=${K_VAL})
	endforeach(K_VAL)
endforeach(D_VAL)

build_ceres("BA" "DO_BA")
build_ceres("Hand" "DO_HAND")
build_ceres("Hand-Eigen" "DO_HAND" "DO_EIGEN")

# Copy GLOG DLL
file(COPY ${GLOG_DLL} DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
