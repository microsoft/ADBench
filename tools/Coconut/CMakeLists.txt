project("Tools-Coconut")

function(build_manual EXE_NAME MODE)
    add_executable("Tools-Coconut-${EXE_NAME}" "coconut_gmm_toplevel.cpp" ${ARGN})
    target_compile_definitions("Tools-Coconut-${EXE_NAME}" PUBLIC ${MODE} "DO_CPP" "BUMP")
endfunction(build_manual)

build_manual("GMM" "DO_GMM" "marshal.c")
