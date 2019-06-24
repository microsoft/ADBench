project("CppRunnerTests" CXX)

add_executable(cppRunnerTests CppRunnerTests.cpp "../../../src/cpp/runner/ModuleLoader.cpp")
target_link_libraries(cppRunnerTests PUBLIC GMock::main) 

add_library(MockGMM MODULE "MockGMM.cpp")
target_link_libraries(MockGMM PUBLIC GMock::main) 

add_test("cppRunnerTests" cppRunnerTests)
