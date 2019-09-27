project(PythonModuleCommonTests)

add_test(
    NAME PythonModuleCommonTests
    COMMAND "python" "-m" "unittest" "discover" "${CMAKE_SOURCE_DIR}/test/python/modules/common" "*.py")