# CMakeList.txt : Top-level CMake project file, do global configuration
# and include sub-projects here.
#
cmake_minimum_required (VERSION 3.6)

# Set build type variable
#	so RelWithDebInfo is treated as Release
if (${CMAKE_BUILD_TYPE} MATCHES "Debug")
	set(AD_BUILD_TYPE "Debug")
else ()
	set(AD_BUILD_TYPE "Release")
endif ()


set(HUNTER_STATUS_DEBUG ON)
set(HUNTER_BUILD_SHARED_LIBS OFF)

# Get HunterGate package manager
set(ENV{HUNTER_ROOT} "etc/HunterGate-Root")
include("etc/HunterGate.cmake")

HunterGate(
    URL "https://github.com/ruslo/hunter/archive/v0.23.6.tar.gz"
    SHA1 "951e8daf57a51708b0e6a00cab342a042db57a2f"
	LOCAL
)

# Declare project name
project ("ADBench")

# Get project-wide dependencies
hunter_add_package(Eigen)
find_package(Eigen3 REQUIRED)
include_directories("${EIGEN_ROOT}/share/eigen3/cmake")
include_directories("${EIGEN3_INCLUDE_DIRS}")

# Set constants
set(GMM_D_VALS 2 10) # set(D_VALS 2 10 20 32 64)
set(GMM_K_VALS 5 10 25 50) # set(K_VALS 5 10 25 50 100 200)
# TODO figure out why Ceres build crashes

# Include sub-projects.
add_subdirectory ("ADBench")
add_subdirectory ("tools")
