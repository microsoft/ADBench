project("ADBench_Finite" CXX)

add_library("Finite" MODULE)
target_sources("Finite" PRIVATE "${CMAKE_SOURCE_DIR}/src/cpp/shared/utils.cpp")
target_sources("Finite" PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/FiniteGMM.cpp")
target_sources("Finite" PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/FiniteBA.cpp")
target_sources("Finite" PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/FiniteHand.cpp")
target_sources("Finite" PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/FiniteLSTM.cpp")