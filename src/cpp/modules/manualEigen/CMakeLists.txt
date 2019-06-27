project("ADBench_ManualEigen" CXX)

add_library("ManualEigen" MODULE)
target_sources("ManualEigen" PRIVATE "gmm_d.cpp")
target_sources("ManualEigen" PRIVATE "ba_d.cpp")
target_sources("ManualEigen" PRIVATE "${CMAKE_SOURCE_DIR}/src/cpp/shared/utils.cpp")
target_sources("ManualEigen" PUBLIC "ManualEigenGMM.cpp")
target_sources("ManualEigen" PUBLIC "ManualEigenBA.cpp")