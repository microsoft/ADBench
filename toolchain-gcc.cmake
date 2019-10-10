# If CMAKE_C_COMPILER and CMAKE_CXX_COMPILER are set only on the cmake
# command line then they do not propagate to third party Hunter
# packages.  See
#
# https://docs.hunter.sh/en/latest/overview/customization/toolchain-id.html
#
# This turns out not to be a problem if we are doing a local build on
# a Windows machine with only VS installed.  However, the VS2017 Azure
# Dev Ops host also has MinGW installed and the Boost compile process
# picks up that compiler incorrectly on runs of CMake other than the
# first.  See, for example,
#
# https://github.com/ruslo/hunter/issues/946
#
# We have to set these flags in this toolchain file for them to
# propagate correctly.

set(CMAKE_C_COMPILER gcc)
set(CMAKE_CXX_COMPILER g++)
