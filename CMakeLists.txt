# CMakeList.txt : Top-level CMake project file, do global configuration
# and include sub-projects here.
#
cmake_minimum_required (VERSION 3.12)

# Set build type variable
# so RelWithDebInfo is treated as Release
if (${CMAKE_BUILD_TYPE} MATCHES "Debug")
    set(AD_BUILD_TYPE "Debug")
else ()
    set(AD_BUILD_TYPE "Release")
endif ()

# $<1:> always resolves to empty string, but the fact, that a generator
# expression is used, forces Visual Studio generator to not create
# configuration-specific folders for outputs, thus making output paths
# consistent between different generators.
# See https://cmake.org/cmake/help/v3.5/prop_tgt/RUNTIME_OUTPUT_DIRECTORY.html#prop_tgt:RUNTIME_OUTPUT_DIRECTORY
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY $<1:>)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY $<1:>)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY $<1:>)


set(HUNTER_STATUS_DEBUG OFF)
set(HUNTER_BUILD_SHARED_LIBS OFF)

# Get HunterGate package manager
if(NOT DEFINED ENV{HUNTER_ROOT})
    set(ENV{HUNTER_ROOT} "etc/HunterGate-Root-awf")
    message(STATUS "Setting HUNTER_ROOT to $ENV{HUNTER_ROOT}")
endif()
include("etc/HunterGate.cmake")

HunterGate(
    URL "https://github.com/ruslo/hunter/archive/v0.23.177.tar.gz"
    SHA1 "c3d4bf987a1c5f8ce9bb8b2b80bc6c123185cd66"
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
set(GMM_D_VALS 2 10 20 32 64 128)
set(GMM_K_VALS 5 10 25 50 100 200)
# TODO figure out why Ceres build crashes

# Make all platforms use .exe extensions for executables, for the
# benefit of other tooling.
set(CMAKE_EXECUTABLE_SUFFIX .exe)

# Make all platforms don't use any prefixes for libraries.
set(CMAKE_SHARED_LIBRARY_PREFIX "")
set(CMAKE_SHARED_MODULE_PREFIX "")

# Make all platforms use .dll extensions for executables 
# to simplify the use of modules.
set(CMAKE_SHARED_LIBRARY_SUFFIX .dll)
set(CMAKE_SHARED_MODULE_SUFFIX .dll)

# Make all platforms use similar names for release and debug binaries.
set(CMAKE_DEBUG_POSTFIX "")

# Enable C++14 features for all C++ code.
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# Include sub-projects.
add_subdirectory ("ADBench")
add_subdirectory ("src")
add_subdirectory ("tools")

# Enable tests
option(ENABLE_TESTS "Enable tests" ON)

if (${ENABLE_TESTS})
    # Get gtest and gmock packages
    hunter_add_package(GTest)
	
	find_package (GTest CONFIG REQUIRED)
    find_package(GMock CONFIG REQUIRED)

    if(NOT EXISTS "${GTest_LICENSES}")
        message(FATAL_ERROR "File not found: '${GTest_LICENSES}")
    endif()
    message("License file: '${GTest_LICENSES}'")

    enable_testing()
	add_subdirectory ("test")
endif()

