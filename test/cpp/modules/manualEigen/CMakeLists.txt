project("ManualEigenDifferentiationTests" CXX)

add_executable(manualEigenGMMTests ManualEigenGMMTests.cpp "../../../../src/cpp/runner/ModuleLoader.cpp")

add_test("manualEigenGMMTests" manualEigenGMMTests)
target_link_libraries(manualEigenGMMTests PUBLIC GTest::main)
target_link_libraries(manualEigenGMMTests INTERFACE ManualEigenGMM)
add_custom_command(TARGET manualEigenGMMTests PRE_BUILD 
    COMMAND "${CMAKE_COMMAND}" -E copy 
        "$<TARGET_FILE:ManualEigenGMM>"
        "${CMAKE_CURRENT_BINARY_DIR}")