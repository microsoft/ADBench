
project("Tools-Adept")

add_executable("Tools-Adept-GMM" "main.cpp" "include/adept.h")
target_compile_definitions("Tools-Adept-GMM" PUBLIC "DO_GMM_FULL")
target_link_libraries("Tools-Adept-GMM" "${CMAKE_CURRENT_LIST_DIR}/lib/Debug/Adeptd.lib")
# target_link_libraries("Tools-Adept-GMM" "${CMAKE_CURRENT_LIST_DIR}/lib/Release/Adept.lib")
# target_link_libraries("Tools-Adept-GMM" "${CMAKE_CURRENT_LIST_DIR}/lib/Release/vxl/vnl.lib")
