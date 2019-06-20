project("CppRunner" CXX)

add_executable("CppRunner" "main.cpp" "ModuleLoader.cpp" "OutputSave.cpp" "../shared/utils.cpp")