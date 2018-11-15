project("Tools-Knossos")

function(build_manual EXE_NAME MODE)
    add_executable("Tools-Knossos-${EXE_NAME}" "knossos_gmm_toplevel.cpp" ${ARGN})
    target_compile_definitions("Tools-Knossos-${EXE_NAME}" PUBLIC ${MODE} "DO_CPP")
endfunction(build_manual)

build_manual("GMM" "DO_GMM" "gmm.cpp" "knossos.cpp")
