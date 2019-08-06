project("FinitePartialGmm" CXX)

add_executable("FinitePartialGmm" "main.cpp" "${CMAKE_SOURCE_DIR}/src/cpp/shared/utils.cpp" "${CMAKE_SOURCE_DIR}/src/cpp/runner/OutputSave.cpp" "${CMAKE_SOURCE_DIR}/src/cpp/runner/Filepaths.cpp")