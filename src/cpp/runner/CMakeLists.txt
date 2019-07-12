project("CppRunner" CXX)

set(TestExtenders "GMMBenchmark.cpp" "BABenchmark.cpp" "HandBenchmark.cpp" "LSTMBenchmark.cpp")
add_executable("CppRunner" ${TestExtenders} "Filepaths.cpp" "ModuleLoader.cpp" "OutputSave.cpp" "../shared/utils.cpp"  "main.cpp")

if (UNIX)
	target_link_libraries("CppRunner" dl)
endif (UNIX)