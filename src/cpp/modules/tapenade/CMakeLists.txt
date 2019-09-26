project("ADBench_Tapenade" CXX)

add_library("Tapenade" MODULE)
target_sources("Tapenade" PRIVATE "${CMAKE_SOURCE_DIR}/src/cpp/shared/utils.cpp")
target_sources("Tapenade" PRIVATE "utils/adBuffer.c")
target_sources("Tapenade" PRIVATE "utils/adStack.c")

target_sources("Tapenade" PRIVATE "lstm/lstm.c")
target_sources("Tapenade" PRIVATE "lstm/lstm_b.c")
target_sources("Tapenade" PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/TapenadeLSTM.cpp")

target_sources("Tapenade" PRIVATE "gmm/gmm.c")
target_sources("Tapenade" PRIVATE "gmm/gmm_b.c")
target_sources("Tapenade" PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/TapenadeGMM.cpp")

target_sources("Tapenade" PRIVATE "ba/ba.c")
target_sources("Tapenade" PRIVATE "ba/ba_b.c")
target_sources("Tapenade" PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/TapenadeBA.cpp")

target_sources("Tapenade" PRIVATE "hand/hand.c")
target_sources("Tapenade" PRIVATE "hand/hand_d.c")
target_sources("Tapenade" PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/TapenadeHand.cpp")