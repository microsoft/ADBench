project("ADBench_Tapenade" CXX)

add_library("Tapenade" MODULE)
target_sources("Tapenade" PRIVATE "${CMAKE_SOURCE_DIR}/src/cpp/shared/utils.cpp")
target_sources("Tapenade" PRIVATE "utils/adBuffer.cpp")
target_sources("Tapenade" PRIVATE "utils/adStack.cpp")
target_sources("Tapenade" PRIVATE "utils/helpers.cpp")

target_sources("Tapenade" PRIVATE "lstm/lstm.cpp")
target_sources("Tapenade" PRIVATE "lstm/lstm_d.cpp")
target_sources("Tapenade" PUBLIC "TapenadeLSTM.cpp")

target_sources("Tapenade" PRIVATE "gmm/gmm.cpp")
target_sources("Tapenade" PRIVATE "gmm/gmm_d.cpp")
target_sources("Tapenade" PUBLIC "TapenadeGMM.cpp")

target_sources("Tapenade" PRIVATE "ba.cpp")
target_sources("Tapenade" PRIVATE "ba_d.cpp")
target_sources("Tapenade" PUBLIC "TapenadeBA.cpp")