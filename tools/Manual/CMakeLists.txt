project("Tools-Manual")

function(build_manual EXE_NAME MODE EIGEN)
	if(${EIGEN})
		add_executable("Tools-Manual-${EXE_NAME}" "main.cpp" "${CMAKE_SOURCE_DIR}/src/cpp/shared/utils.cpp" ${ARGN})
		target_compile_definitions("Tools-Manual-${EXE_NAME}" PUBLIC ${MODE} "DO_EIGEN")
	else()
		add_executable("Tools-Manual-${EXE_NAME}" "main.cpp" "${CMAKE_SOURCE_DIR}/src/cpp/shared/utils.cpp" ${ARGN})
		target_compile_definitions("Tools-Manual-${EXE_NAME}" PUBLIC ${MODE} "DO_CPP")
	endif()
endfunction(build_manual)

build_manual("GMM" "DO_GMM" OFF "gmm_d.cpp" "gmm_d.h")
build_manual("GMM-Eigen" "DO_GMM" ON "gmm_d.cpp" "gmm_d.h")

# build_manual("BA" "DO_BA" OFF "ba_d.cpp" "ba_d.h")
build_manual("BA-Eigen" "DO_BA" ON "ba_d.cpp" "ba_d.h")
# TODO this builds BA with Eigen only, because fails without

# build_manual("Hand-Light-simple" "DO_HAND" OFF)
# build_manual("Hand-Light-complicated" "DO_HAND_COMPLICATED" OFF)
build_manual("Hand-Eigen-simple" "DO_HAND" ON "hand_eigen_d.h")
build_manual("Hand-Eigen-complicated" "DO_HAND_COMPLICATED" ON "hand_eigen_d.h")