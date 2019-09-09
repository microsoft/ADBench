add_test(
    NAME PythonRunnerTests
    COMMAND "python" "-m" "unittest" "discover" "${CMAKE_SOURCE_DIR}/test/python/runner" "*.py")