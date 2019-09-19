project("JuliaRunnerTests")

add_test(
    NAME TestJuliaRunner
    COMMAND "julia" "--project=${CMAKE_SOURCE_DIR}" "--optimize=3" "${CMAKE_CURRENT_LIST_DIR}/RunnerTests.jl")