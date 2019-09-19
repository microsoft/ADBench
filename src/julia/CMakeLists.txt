project("Julia")

execute_process(COMMAND "julia" "--project=${CMAKE_SOURCE_DIR}" "-E using Pkg; Pkg.instantiate()")