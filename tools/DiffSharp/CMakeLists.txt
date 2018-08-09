project("Tools-DiffSharp" "F#")

add_executable("Tools-DiffSharp-GMM" "Program.fs")
target_compile_definitions("Tools-DiffSharp-GMM" PUBLIC "DO_GMM_FULL")
#target_link_libraries("Tools-DiffSharp-GMM" "${CMAKE_CURRENT_BINARY_DIR}/Adept-2d.lib")
