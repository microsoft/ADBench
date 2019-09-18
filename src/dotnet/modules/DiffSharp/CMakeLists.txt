project("ADBench_DiffSharp")

execute_process(COMMAND "${CMAKE_CURRENT_LIST_DIR}/build.bat" "${CMAKE_CURRENT_LIST_DIR}" "${CMAKE_CURRENT_BINARY_DIR}" "${config}")
