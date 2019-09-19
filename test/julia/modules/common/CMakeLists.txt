project("JuliaModulesCommonTests")

add_test(
    NAME TestJuliaGmmModules
    COMMAND "julia" "--project=${CMAKE_SOURCE_DIR}" "--optimize=3" "${CMAKE_CURRENT_LIST_DIR}/GmmTests.jl")