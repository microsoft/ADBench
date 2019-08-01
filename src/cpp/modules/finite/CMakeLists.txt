project("ADBench_Finite" CXX)

add_library("Finite" MODULE)
target_sources("Finite" PRIVATE "${CMAKE_SOURCE_DIR}/src/cpp/shared/utils.cpp")
target_sources("Finite" PUBLIC "FiniteGMM.cpp")
target_sources("Finite" PUBLIC "FiniteBA.cpp")
target_sources("Finite" PUBLIC "FiniteHand.cpp")
target_sources("Finite" PUBLIC "FiniteLSTM.cpp")