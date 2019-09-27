add_custom_target(copyPythonTestFile)

add_custom_command(TARGET copyPythonTestFile PRE_BUILD 
    COMMAND "${CMAKE_COMMAND}" -E copy 
        "${CMAKE_SOURCE_DIR}/data/gmm/test.txt"
        "${CMAKE_CURRENT_BINARY_DIR}/gmmtest.txt")
add_custom_command(TARGET copyPythonTestFile PRE_BUILD 
    COMMAND "${CMAKE_COMMAND}" -E copy 
        "${CMAKE_SOURCE_DIR}/data/ba/test.txt"
        "${CMAKE_CURRENT_BINARY_DIR}/batest.txt")
add_custom_command(TARGET copyPythonTestFile PRE_BUILD 
    COMMAND "${CMAKE_COMMAND}" -E copy 
        "${CMAKE_SOURCE_DIR}/data/hand/test.txt"
        "${CMAKE_CURRENT_BINARY_DIR}/handtestsmall.txt")
add_custom_command(TARGET copyPythonTestFile PRE_BUILD 
    COMMAND "${CMAKE_COMMAND}" -E copy 
        "${CMAKE_SOURCE_DIR}/data/hand/hand_complicated.txt"
        "${CMAKE_CURRENT_BINARY_DIR}/handtestcomplicated.txt")
add_custom_command(TARGET copyPythonTestFile PRE_BUILD 
    COMMAND "${CMAKE_COMMAND}" -E copy_directory 
        "${CMAKE_SOURCE_DIR}/data/hand/model"
        "${CMAKE_CURRENT_BINARY_DIR}/model")
add_custom_command(TARGET copyPythonTestFile PRE_BUILD 
    COMMAND "${CMAKE_COMMAND}" -E copy 
        "${CMAKE_SOURCE_DIR}/data/lstm/lstm_l2_c1024.txt"
        "${CMAKE_CURRENT_BINARY_DIR}/lstmtest.txt")

add_test(
    NAME PythonModuleCommonTests
    COMMAND "python" "-m" "unittest" "discover" "${CMAKE_SOURCE_DIR}/test/python/modules/common" "*.py")