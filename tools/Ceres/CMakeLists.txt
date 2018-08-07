
project("Tools-Ceres")

#set(CERES_DIR "${CMAKE_SOURCE_DIR}/submodules/ceres-solver")

#find_package(Ceres REQUIRED)
#include_directories(${CERES_INCLUDE_DIRS})

#include_directories("${CERES_DIR}/include")

include_directories("${CERES_INCLUDE_DIRS}")

# TODO fix
#add_executable("Tools-Ceres-GMM" "main.cpp" "${CERES-SOLVER_ROOT}/include/ceres/ceres.h")
#target_compile_definitions("Tools-Ceres-GMM" PUBLIC "DO_GMM")
#target_include_directories("Tools-Ceres-GMM" PRIVATE "${CMAKE_CURRENT_LIST_DIR}/include")
#target_link_libraries("Tools-Ceres-GMM" "${CMAKE_CURRENT_LIST_DIR}/lib/ceres.lib" "${CMAKE_CURRENT_LIST_DIR}/lib/libglog.lib")
#target_link_libraries("Tools-Ceres-GMM" "${CERES-SOLVER_ROOT}/lib/ceres-debug.lib" "${CERES-SOLVER_ROOT}/lib/glogd.lib")

add_executable("Tools-Ceres-BA" "main.cpp" "${CERES-SOLVER_ROOT}/include/ceres/ceres.h")
target_compile_definitions("Tools-Ceres-BA" PUBLIC "DO_BA")
#target_include_directories("Tools-Ceres-BA" PRIVATE "${CMAKE_CURRENT_LIST_DIR}/include")
#target_link_libraries("Tools-Ceres-BA" "${CMAKE_CURRENT_LIST_DIR}/lib/ceres.lib" "${CMAKE_CURRENT_LIST_DIR}/lib/libglog.lib")
target_link_libraries("Tools-Ceres-BA" "${CERES-SOLVER_ROOT}/lib/ceres-debug.lib" "${CERES-SOLVER_ROOT}/lib/glogd.lib")

#file(COPY "${CMAKE_CURRENT_LIST_DIR}/../cpp-common/bin/libglog.dll" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")

# NOTE GMM seems to need old libglog.lib, but BA seems to need new glogd.lib
