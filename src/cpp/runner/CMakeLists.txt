project("CppRunner" CXX)

add_executable("CppRunner" "BABenchmark.cpp" "GMMBenchmark.cpp" "Benchmark.cpp" "ModuleLoader.cpp" "OutputSave.cpp" "../shared/utils.cpp"  "main.cpp")