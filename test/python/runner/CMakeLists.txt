add_test(
    NAME PythonRunnerTests
    COMMAND ${Python3_EXECUTABLE} "-m" "unittest" "discover" 
    "${CMAKE_SOURCE_DIR}/test/python/runner" "*.py"
    )