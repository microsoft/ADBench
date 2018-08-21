
project("Tools-ADOLC")

# Find Boost
hunter_add_package(Boost)
find_package(Boost CONFIG REQUIRED)

# ADOL-C submodule dir
set(ADOLC_SRC_DIR "${CMAKE_SOURCE_DIR}/submodules/adol-c")
set(ADOLC_BIN_DIR "${CMAKE_CURRENT_BINARY_DIR}/adol-c")

# Build ADOL-C
if (WIN32)
	message("Running ADOL-C build.bat")
	execute_process(COMMAND "${CMAKE_CURRENT_LIST_DIR}/build.bat" "${ADOLC_SRC_DIR}" "${ADOLC_BIN_DIR}" "${BOOST_ROOT}/include")
	message("Finished ADOL-C build.bat")
endif()

# Include ADOL-C
set(ADOLC_INCLUDE_DIR "${ADOLC_SRC_DIR}/ADOL-C/include")
include_directories(${ADOLC_INCLUDE_DIR})

function(build_adolc EXE_NAME)
	add_executable("Tools-ADOLC-${EXE_NAME}" "main.cpp" "${ADOLC_INCLUDE_DIR}/adolc/adolc.h")
	target_compile_definitions("Tools-ADOLC-${EXE_NAME}" PUBLIC ${ARGN})
	target_link_libraries("Tools-ADOLC-${EXE_NAME}" "${CMAKE_CURRENT_BINARY_DIR}/adol-c/adolc.lib")
endfunction(build_adolc)

build_adolc("GMM-FULL" "DO_GMM_FULL" "DO_CPP")
build_adolc("GMM-SPLIT" "DO_GMM_SPLIT" "DO_CPP")

build_adolc("BA" "DO_BA_BLOCK" "DO_CPP")
# build_adolc("BA-Eigen" "DO_BA_BLOCK" "DO_EIGEN")
# TODO this doesn't work

build_adolc("Hand-simple" "DO_HAND")
build_adolc("Hand-complicated" "DO_HAND_COMPLICATED")
build_adolc("Hand-Eigen-simple" "DO_HAND" "DO_EIGEN")
build_adolc("Hand-Eigen-complicated" "DO_HAND_COMPLICATED" "DO_EIGEN")

# Copy DLL
file(COPY "${ADOLC_BIN_DIR}/adolc.dll" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
