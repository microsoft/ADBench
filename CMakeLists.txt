# CMakeList.txt : Top-level CMake project file, do global configuration
# and include sub-projects here.
#
cmake_minimum_required (VERSION 3.8)

# Get HunterGate package manager
set(ENV{HUNTER_ROOT} "etc/HunterGate-Root")
include("etc/HunterGate.cmake")

HunterGate(
    URL "https://github.com/ruslo/hunter/archive/v0.23.6.tar.gz"
    SHA1 "951e8daf57a51708b0e6a00cab342a042db57a2f"
)

# Declare project name
project ("ADBench")

# Try to get dependencies
#hunter_add_package(Eigen VERSION 3.2.5)
#find_package(Eigen VERSION 3.2.5)


# Include sub-projects.
add_subdirectory ("ADBench")
add_subdirectory ("tools")
