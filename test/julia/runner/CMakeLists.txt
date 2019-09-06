project("JuliaRunnerTests")

add_test(
    NAME TestJuliaRunner
    COMMAND "julia" "${CMAKE_CURRENT_LIST_DIR}/RunnerTests.jl")