
project("Tools-ADOLC")

# Find Boost
hunter_add_package(Boost)
find_package(Boost CONFIG REQUIRED)

# ADOL-C submodule dir
set(ADOLC_SRC_DIR "${CMAKE_SOURCE_DIR}/submodules/adol-c")
set(ADOLC_BIN_DIR "${CMAKE_CURRENT_BINARY_DIR}/adol-c")

# Build ADOL-C
if (WIN32)
	message("Running ADOL-C build.bat")
	execute_process(COMMAND "${CMAKE_CURRENT_LIST_DIR}/build.bat" "${ADOLC_SRC_DIR}" "${ADOLC_BIN_DIR}" "${BOOST_ROOT}/include")
	message("Finished ADOL-C build.bat")
endif()

# Include ADOL-C
set(ADOLC_INCLUDE_DIR "${ADOLC_SRC_DIR}/ADOL-C/include")
include_directories(${ADOLC_INCLUDE_DIR})

# Build GMM
add_executable("Tools-ADOLC-GMM" "main.cpp" "${ADOLC_INCLUDE_DIR}/adolc/adolc.h")
target_compile_definitions("Tools-ADOLC-GMM" PUBLIC "DO_GMM_FULL" "DO_CPP")
#target_include_directories("Tools-ADOLC-GMM" PRIVATE ${ADOLC_INCLUDE_DIR})
target_link_libraries("Tools-ADOLC-GMM" "${CMAKE_CURRENT_BINARY_DIR}/adol-c/adolc.lib")

# Build BA
add_executable("Tools-ADOLC-BA" "main.cpp" "${ADOLC_INCLUDE_DIR}/adolc/adolc.h")
target_compile_definitions("Tools-ADOLC-BA" PUBLIC "DO_BA_BLOCK" "DO_CPP")
#target_include_directories("Tools-ADOLC-BA" PRIVATE ${ADOLC_INCLUDE_DIR})
target_link_libraries("Tools-ADOLC-BA" "${CMAKE_CURRENT_BINARY_DIR}/adol-c/adolc.lib")

# Copy DLL
file(COPY "${ADOLC_BIN_DIR}/adolc.dll" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
