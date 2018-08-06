
project("Tools-Manual")

add_executable("Tools-Manual-GMM" "main.cpp" "gmm_d.cpp" "gmm_d.h")
target_compile_definitions("Tools-Manual-GMM" PUBLIC "DO_GMM")

add_executable("Tools-Manual-BA" "main.cpp" "ba_d.cpp" "ba_d.h")
target_compile_definitions("Tools-Manual-BA" PUBLIC "DO_BA" "DO_EIGEN")
