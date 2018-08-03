
project("Tools-Adept")

set(ADEPT_DIR "${CMAKE_SOURCE_DIR}/submodules/Adept-2")

include_directories("${ADEPT_DIR}/include")

add_library("Adept-2" STATIC "${ADEPT_DIR}/include/adept.h" "${ADEPT_DIR}/adept/Stack.cpp" "${ADEPT_DIR}/adept/StackStorageOrig.cpp" "${ADEPT_DIR}/adept/jacobian.cpp")

add_executable("Tools-Adept-GMM" "main.cpp" "${ADEPT_DIR}/include/adept.h")
target_compile_definitions("Tools-Adept-GMM" PUBLIC "DO_GMM_FULL")
target_link_libraries("Tools-Adept-GMM" "${CMAKE_CURRENT_BINARY_DIR}/Adept-2d.lib")

add_executable("Tools-Adept-BA" "main.cpp" "${ADEPT_DIR}/include/adept.h")
target_compile_definitions("Tools-Adept-BA" PUBLIC "DO_BA")
target_link_libraries("Tools-Adept-BA" "${CMAKE_CURRENT_BINARY_DIR}/Adept-2d.lib")
