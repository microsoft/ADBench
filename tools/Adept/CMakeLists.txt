
project("Tools-Adept")

add_executable("Tools-Adept-GMM" "main.cpp" "include/adept.h")
target_compile_definitions("Tools-Adept-GMM" PUBLIC "DO_GMM_FULL")
target_link_libraries("Tools-Adept-GMM" "${CMAKE_CURRENT_LIST_DIR}/lib/Debug/Adeptd.lib")

add_executable("Tools-Adept-BA" "main.cpp" "include/adept.h")
target_compile_definitions("Tools-Adept-BA" PUBLIC "DO_BA")
target_link_libraries("Tools-Adept-BA" "${CMAKE_CURRENT_LIST_DIR}/lib/Debug/Adeptd.lib")
