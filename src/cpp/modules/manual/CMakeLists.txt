project("ADBench_Manual" CXX)

add_library("Manual" MODULE)
target_sources("Manual" PRIVATE "gmm_d.cpp")
target_sources("Manual" PRIVATE "ba_d.cpp")
target_sources("Manual" PRIVATE "${CMAKE_SOURCE_DIR}/src/cpp/shared/utils.cpp")
target_sources("Manual" PUBLIC "ManualGMM.cpp")
target_sources("Manual" PUBLIC "ManualBA.cpp")