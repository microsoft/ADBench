project("ManualDifferentiationTests" CXX)

add_executable(manualGMMTests ManualGMMTests.cpp "../../../../src/cpp/runner/ModuleLoader.cpp")

add_test("manualGMMTests" manualGMMTests)
target_link_libraries(manualGMMTests PUBLIC GTest::main)
target_link_libraries(manualGMMTests INTERFACE ManualGMM)
add_custom_command(TARGET manualGMMTests PRE_BUILD 
    COMMAND "${CMAKE_COMMAND}" -E copy 
        "$<TARGET_FILE:ManualGMM>"
        "${CMAKE_CURRENT_BINARY_DIR}")