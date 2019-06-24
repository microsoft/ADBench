project("ManualEigenDifferentiationTests" CXX)

add_executable(manualEigenTests GmmTests.cpp "../../../../src/cpp/runner/ModuleLoader.cpp")

add_test("manualEigenGmmTests" manualEigenTests)
target_link_libraries(manualEigenTests PUBLIC GTest::main)
target_link_libraries(manualEigenTests INTERFACE ManualEigen)
add_custom_command(TARGET manualEigenTests PRE_BUILD 
    COMMAND "${CMAKE_COMMAND}" -E copy 
        "$<TARGET_FILE:ManualEigen>"
        "${CMAKE_CURRENT_BINARY_DIR}")
add_custom_command(TARGET manualEigenTests PRE_BUILD 
    COMMAND "${CMAKE_COMMAND}" -E copy 
        "${CMAKE_SOURCE_DIR}/data/gmm/test.txt"
        "${CMAKE_CURRENT_BINARY_DIR}/gmmtest.txt")