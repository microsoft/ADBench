
project("Tools-Finite")

add_executable("Tools-Finite-GMM" "main.cpp")
target_compile_definitions("Tools-Finite-GMM" PUBLIC "DO_GMM")

add_executable("Tools-Finite-BA" "main.cpp")
target_compile_definitions("Tools-Finite-BA" PUBLIC "DO_BA")

add_executable("Tools-Finite-Hand" "main.cpp")
target_compile_definitions("Tools-Finite-Hand" PUBLIC "DO_HAND" "DO_EIGEN")
