project("ADBench_FiniteEigen" CXX)

add_library("FiniteEigen" MODULE)
target_sources("FiniteEigen" PRIVATE "${CMAKE_SOURCE_DIR}/src/cpp/shared/utils.cpp")
target_sources("FiniteEigen" PUBLIC "FiniteEigenHand.cpp")