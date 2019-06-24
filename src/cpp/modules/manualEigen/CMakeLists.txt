project("ManualEigenDifferentiation" CXX)

add_library("ManualEigen" MODULE)
target_sources("ManualEigen" PRIVATE "gmm_d.cpp")
target_sources("ManualEigen" PUBLIC "ManualEigenGMM.cpp")