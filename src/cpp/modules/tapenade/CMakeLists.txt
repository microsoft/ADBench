project("ADBench_Tapenade" CXX)

add_library("Tapenade" MODULE)
target_sources("Tapenade" PRIVATE "${CMAKE_SOURCE_DIR}/src/cpp/shared/utils.cpp")

target_sources("Tapenade" PRIVATE "lstm.cpp")
target_sources("Tapenade" PRIVATE "lstm_d.cpp")
target_sources("Tapenade" PUBLIC "TapenadeLSTM.cpp")

target_sources("Tapenade" PRIVATE "gmm.cpp")
target_sources("Tapenade" PRIVATE "gmm_d.cpp")
target_sources("Tapenade" PUBLIC "TapenadeGMM.cpp")