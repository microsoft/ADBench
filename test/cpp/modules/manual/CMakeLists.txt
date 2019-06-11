project("ManualDifferentiationTests" CXX)

add_executable(manualGMMTests ManualGMMTests.cpp "../../../../src/cpp/modules/manual/ManualGMM.cpp")

add_test("manualGMMTests" manualGMMTests)
target_link_libraries(manualGMMTests PUBLIC GTest::main)