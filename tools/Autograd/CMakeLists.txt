project(Autograd)

set (Python3_FIND_REGISTRY NEVER)
find_package(Python3 COMPONENTS Interpreter)

if (${Python3_Interpreter_FOUND})
    execute_process(
        COMMAND ${Python3_EXECUTABLE} "-m" "pip" "install"
        "-r" "${CMAKE_CURRENT_SOURCE_DIR}/requirements.txt"
        )
else()
    message(WARNING "Python3 Interpreter not found")
endif()