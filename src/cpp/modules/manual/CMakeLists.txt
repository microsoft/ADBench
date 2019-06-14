project("ManualDifferentiation" CXX)

add_library("ManualGMM" MODULE)
target_sources("ManualGMM" PRIVATE "gmm_d.cpp")
target_sources("ManualGMM" PRIVATE "ba_d.cpp")
target_sources("ManualGMM" PUBLIC "ManualGMM.cpp")
target_sources("ManualGMM" PUBLIC "ManualBA.cpp")