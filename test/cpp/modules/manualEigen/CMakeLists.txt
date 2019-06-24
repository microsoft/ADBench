project("ManualEigenDifferentiationTests" CXX)
add_executable(manualEigenTests GmmTests.cpp "${CMAKE_SOURCE_DIR}/src/cpp/runner/ModuleLoader.cpp" "${CMAKE_SOURCE_DIR}/src/cpp/shared/utils.cpp")

add_test("manualEigenTests" manualEigenTests)
add_dependencies(manualEigenTests ManualEigen)
target_link_libraries(manualEigenTests PUBLIC GTest::main)
add_custom_command(TARGET manualEigenTests PRE_BUILD 
    COMMAND "${CMAKE_COMMAND}" -E copy 
        "${CMAKE_SOURCE_DIR}/data/gmm/test.txt"
        "${CMAKE_CURRENT_BINARY_DIR}/gmmtest.txt")