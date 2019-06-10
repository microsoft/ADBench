project("CppRunnerTests" CXX)

add_executable(cppRunnerTests CppRunnerTests.cpp "../../../src/runners/cpp/ModuleLoader.cpp")
add_library("GMMDummy" SHARED "GMMDummy.cpp")

add_test("cppRunnerTests" cppRunnerTests)
target_link_libraries(cppRunnerTests PUBLIC GTest::main) 