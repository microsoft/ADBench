project("ManualEigenDifferentiation" CXX)

add_library("ManualEigenGMM" MODULE)
target_sources("ManualEigenGMM" PRIVATE "gmm_eigen.cpp")
target_sources("ManualEigenGMM" PUBLIC "ManualEigenGMM.cpp")