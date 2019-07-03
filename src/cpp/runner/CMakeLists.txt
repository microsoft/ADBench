project("CppRunner" CXX)

set(TestExtenders "GMMBenchmark.cpp" "BABenchmark.cpp" "HandBenchmark.cpp" "LSTMBenchmark.cpp")
add_executable("CppRunner" ${TestExtenders} "Benchmark.cpp" "Filepaths.cpp" "ModuleLoader.cpp" "OutputSave.cpp" "../shared/utils.cpp"  "main.cpp")