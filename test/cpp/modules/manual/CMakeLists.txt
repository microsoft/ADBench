include(GoogleTest)

project("ManualTests" CXX)
add_executable(manualTests "${CMAKE_SOURCE_DIR}/src/cpp/runner/ModuleLoader.cpp" "${CMAKE_SOURCE_DIR}/src/cpp/runner/Filepaths.cpp" "${CMAKE_SOURCE_DIR}/src/cpp/shared/utils.cpp")
target_sources("manualTests" PUBLIC "ModuleTest.cpp")
target_sources("manualTests" PUBLIC "GmmTests.cpp")
target_sources("manualTests" PUBLIC "BaTests.cpp")
target_sources("manualTests" PUBLIC "HandTests.cpp")
target_sources("manualTests" PUBLIC "LstmTests.cpp")

if (UNIX)
	#link library to work with shared libraries
	target_link_libraries(manualTests PUBLIC dl)
endif (UNIX)

gtest_add_tests(manualTests "" AUTO)
add_dependencies(manualTests Manual)
target_link_libraries(manualTests PUBLIC GTest::main)
add_custom_command(TARGET manualTests PRE_BUILD 
    COMMAND "${CMAKE_COMMAND}" -E copy 
        "${CMAKE_SOURCE_DIR}/data/gmm/test.txt"
        "${CMAKE_CURRENT_BINARY_DIR}/gmmtest.txt")
add_custom_command(TARGET manualTests PRE_BUILD 
    COMMAND "${CMAKE_COMMAND}" -E copy 
        "${CMAKE_SOURCE_DIR}/data/ba/test.txt"
        "${CMAKE_CURRENT_BINARY_DIR}/batest.txt")
add_custom_command(TARGET manualTests PRE_BUILD 
    COMMAND "${CMAKE_COMMAND}" -E copy 
        "${CMAKE_SOURCE_DIR}/data/hand/test.txt"
        "${CMAKE_CURRENT_BINARY_DIR}/handtestsmall.txt")
add_custom_command(TARGET manualTests PRE_BUILD 
    COMMAND "${CMAKE_COMMAND}" -E copy 
        "${CMAKE_SOURCE_DIR}/data/hand/hand_complicated.txt"
        "${CMAKE_CURRENT_BINARY_DIR}/handtestcomplicated.txt")
add_custom_command(TARGET manualTests PRE_BUILD 
    COMMAND "${CMAKE_COMMAND}" -E copy_directory 
        "${CMAKE_SOURCE_DIR}/data/hand/model"
        "${CMAKE_CURRENT_BINARY_DIR}/model")
add_custom_command(TARGET manualTests PRE_BUILD 
    COMMAND "${CMAKE_COMMAND}" -E copy 
        "${CMAKE_SOURCE_DIR}/data/lstm/lstm_l2_c1024.txt"
        "${CMAKE_CURRENT_BINARY_DIR}/lstmtest.txt")