# CMakeList.txt : CMake project for ADBench, include source and define
# project specific logic here.
#
cmake_minimum_required (VERSION 3.8)

# Add source to this project's executable.
# add_executable (ADBench "ADBench.cpp" "ADBench.h")

# TODO: Add tests and install targets if needed.

file(WRITE "${CMAKE_CURRENT_LIST_DIR}/cmake_vars.ps1" "$global:bindir = \"${CMAKE_BINARY_DIR}\"\n")
