
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

function(build_adept EXE_NAME)
	add_executable("Tools-Adept-${EXE_NAME}" "main.cpp" "${ADEPT_DIR}/include/adept.h" "${CMAKE_SOURCE_DIR}/src/cpp/shared/utils.cpp")
	target_compile_definitions("Tools-Adept-${EXE_NAME}" PUBLIC ${ARGN})
	target_link_libraries("Tools-Adept-${EXE_NAME}" ${ADEPT_LIB})
endfunction(build_adept)

build_adept("GMM-FULL" "DO_GMM_FULL")
build_adept("GMM-SPLIT" "DO_GMM_SPLIT")
build_adept("BA" "DO_BA")
build_adept("Hand-simple" "DO_HAND")
build_adept("Hand-complicated" "DO_HAND_COMPLICATED")
