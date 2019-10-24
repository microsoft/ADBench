project("JuliaModulesCommonTests")

add_test(
    NAME TestJuliaGmmModules
    COMMAND "julia" "--project=${CMAKE_SOURCE_DIR}" "--optimize=3" "${CMAKE_CURRENT_LIST_DIR}/GmmTests.jl")

add_test(
    NAME TestJuliaBaModules
    COMMAND "julia" "--project=${CMAKE_SOURCE_DIR}" "--optimize=3" "${CMAKE_CURRENT_LIST_DIR}/BaTests.jl")

add_test(
    NAME TestJuliaHandModules
    COMMAND "julia" "--project=${CMAKE_SOURCE_DIR}" "--optimize=3" "${CMAKE_CURRENT_LIST_DIR}/HandTests.jl")

add_test(
    NAME TestJuliaLstmModules
    COMMAND "julia" "--project=${CMAKE_SOURCE_DIR}" "--optimize=3" "${CMAKE_CURRENT_LIST_DIR}/LstmTests.jl")