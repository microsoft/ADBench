project("ManualDifferentiation" CXX)

SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/src/runners/cpp")
add_library("ManualGMM" SHARED "ManualGMM.cpp")