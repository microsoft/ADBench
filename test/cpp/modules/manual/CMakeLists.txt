project("ManualDifferentiationTests" CXX)

add_executable(manualTests GmmTests.cpp BaTests.cpp "${CMAKE_SOURCE_DIR}/src/cpp/runner/ModuleLoader.cpp" "${CMAKE_SOURCE_DIR}/src/cpp/shared/utils.cpp")

add_test("manualtests" manualTests)
target_link_libraries(manualTests PUBLIC GTest::main)
target_link_libraries(manualTests INTERFACE Manual)
add_custom_command(TARGET manualTests PRE_BUILD 
    COMMAND "${CMAKE_COMMAND}" -E copy 
        "$<TARGET_FILE:Manual>"
        "${CMAKE_CURRENT_BINARY_DIR}")
add_custom_command(TARGET manualTests PRE_BUILD 
    COMMAND "${CMAKE_COMMAND}" -E copy 
        "${CMAKE_SOURCE_DIR}/data/gmm/test.txt"
        "${CMAKE_CURRENT_BINARY_DIR}/gmmtest.txt")
add_custom_command(TARGET manualTests PRE_BUILD 
    COMMAND "${CMAKE_COMMAND}" -E copy 
        "${CMAKE_SOURCE_DIR}/data/ba/test.txt"
        "${CMAKE_CURRENT_BINARY_DIR}/batest.txt")