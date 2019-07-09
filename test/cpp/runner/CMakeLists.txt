include(GoogleTest)

project("CppRunnerTests" CXX)

set(CMAKE_SHARED_LIBRARY_SUFFIX .dll)

add_executable(cppRunnerTests CppRunnerTests.cpp "../../../src/cpp/runner/ModuleLoader.cpp")
target_link_libraries(cppRunnerTests PUBLIC GMock::main) 

if (UNIX)
	target_link_libraries(cppRunnerTests PUBLIC dl)
endif (UNIX)

add_library(MockGMM MODULE "MockGMM.cpp")
target_link_libraries(MockGMM PUBLIC GMock::main) 

gtest_add_tests(cppRunnerTests "" AUTO)