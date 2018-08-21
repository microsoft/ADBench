
project("Tools-Finite")

function(build_finite EXE_NAME)
	add_executable("Tools-Finite-${EXE_NAME}" "main.cpp")
	target_compile_definitions("Tools-Finite-${EXE_NAME}" PUBLIC ${ARGN})
endfunction(build_finite)

build_finite("GMM" "DO_GMM")
build_finite("BA" "DO_BA")
build_finite("Hand-Light-simple" "DO_HAND")
build_finite("Hand-Light-complicated" "DO_HAND")
build_finite("Hand-Eigen-simple" "DO_HAND" "DO_EIGEN")
build_finite("Hand-Eigen-complicated" "DO_HAND" "DO_EIGEN")
