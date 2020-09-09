set (Python3_FIND_REGISTRY NEVER)
find_package(Python3 COMPONENTS Interpreter)

if (${Python3_Interpreter_FOUND})
    add_subdirectory("modules")
else()
    message(WARNING "Python3 Interpreter not found")
endif()