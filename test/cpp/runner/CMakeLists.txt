project("CppRunnerTests" CXX)

add_executable(cppRunnerTests CppRunnerTests.cpp "../../../src/cpp/runner/ModuleLoader.cpp")
add_library("MockGMM" SHARED "MockGMM.cpp")

add_test("cppRunnerTests" cppRunnerTests)
target_link_libraries(cppRunnerTests PUBLIC GTest::main) 