
project("Tools-Adept")

set(ADEPT_DIR "${CMAKE_SOURCE_DIR}/submodules/Adept-2")

include_directories("${ADEPT_DIR}/include")

add_library("Adept-2" STATIC "${ADEPT_DIR}/include/adept.h" "${ADEPT_DIR}/adept/Stack.cpp" "${ADEPT_DIR}/adept/StackStorageOrig.cpp" "${ADEPT_DIR}/adept/jacobian.cpp")

# Select Debug or Release lib path
if (${CMAKE_BUILD_TYPE} MATCHES "Debug")
	set(ADEPT_LIB "${CMAKE_CURRENT_BINARY_DIR}/Adept-2d.lib")
else ()
	set(ADEPT_LIB "${CMAKE_CURRENT_BINARY_DIR}/Adept-2.lib")
endif ()

add_executable("Tools-Adept-GMM-FULL" "main.cpp" "${ADEPT_DIR}/include/adept.h")
target_compile_definitions("Tools-Adept-GMM-FULL" PUBLIC "DO_GMM_FULL")
target_link_libraries("Tools-Adept-GMM-FULL" ${ADEPT_LIB})

add_executable("Tools-Adept-GMM-SPLIT" "main.cpp" "${ADEPT_DIR}/include/adept.h")
target_compile_definitions("Tools-Adept-GMM-SPLIT" PUBLIC "DO_GMM_SPLIT")
target_link_libraries("Tools-Adept-GMM-SPLIT" ${ADEPT_LIB})

add_executable("Tools-Adept-BA" "main.cpp" "${ADEPT_DIR}/include/adept.h")
target_compile_definitions("Tools-Adept-BA" PUBLIC "DO_BA")
target_link_libraries("Tools-Adept-BA" ${ADEPT_LIB})

add_executable("Tools-Adept-Hand" "main.cpp" "${ADEPT_DIR}/include/adept.h")
target_compile_definitions("Tools-Adept-Hand" PUBLIC "DO_HAND")
target_link_libraries("Tools-Adept-Hand" ${ADEPT_LIB})
