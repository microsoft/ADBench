project("CppRunnerTests" CXX)

add_executable(cppRunnerTests CppRunnerTests.cpp)
add_test("cppRunnerTests" cppRunnerTests)
target_link_libraries(cppRunnerTests PUBLIC GTest::main  )