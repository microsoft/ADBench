project("ManualDifferentiationTests" CXX)

add_executable(manualTests ManualGMMTests.cpp "../../../../src/cpp/runner/ModuleLoader.cpp")

add_test("manualests" manualTests)
target_link_libraries(manualTests PUBLIC GTest::main)
target_link_libraries(manualTests INTERFACE Manual)
add_custom_command(TARGET manualTests PRE_BUILD 
    COMMAND "${CMAKE_COMMAND}" -E copy 
        "$<TARGET_FILE:Manual>"
        "${CMAKE_CURRENT_BINARY_DIR}")