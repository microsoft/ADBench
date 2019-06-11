project("ManualDifferentiationTests" CXX)

add_executable(manualGMMTests ManualGMMTests.cpp "../../../../src/cpp/modules/manual/ManualGMM.cpp" "../../../../src/cpp/modules/manual/gmm_d.cpp")

add_test("manualGMMTests" manualGMMTests)
target_link_libraries(manualGMMTests PUBLIC GTest::main)