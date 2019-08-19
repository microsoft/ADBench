project("ADBench_Tapenade" CXX)

add_library("Tapenade" MODULE)
target_sources("Tapenade" PRIVATE "${CMAKE_SOURCE_DIR}/src/cpp/shared/utils.cpp")
target_sources("Tapenade" PUBLIC "TapenadeLSTM.cpp")