project("ADBench_ManualEigenVector" CXX)

add_library("ManualEigenVector" MODULE)
target_sources("ManualEigenVector" PRIVATE "${CMAKE_SOURCE_DIR}/src/cpp/modules/manualEigen/gmm_d.cpp")
target_sources("ManualEigenVector" PRIVATE "gmm_vector_d.cpp")
target_sources("ManualEigenVector" PRIVATE "${CMAKE_SOURCE_DIR}/src/cpp/shared/utils.cpp")
target_sources("ManualEigenVector" PUBLIC "ManualEigenVectorGMM.cpp")