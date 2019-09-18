project("ADBench_dotnet_Runner_Test")

add_custom_target(DotnetRunnerTests ALL
    COMMAND "dotnet" "build" "--configuration" "${AD_BUILD_TYPE}" "--output" "${CMAKE_CURRENT_BINARY_DIR}" "-p:IntermediateOutputPath=${CMAKE_CURRENT_BINARY_DIR}/obj/" "${CMAKE_CURRENT_LIST_DIR}/DotnetRunnerTests.csproj"
    )

# TODO: Maybe, write automatic discovery instead of dumping all tests into one.
add_test(
    NAME DotnetRunnerTests
    COMMAND "dotnet" "test" "--no-build" "--configuration" "${AD_BUILD_TYPE}" "--output" "${CMAKE_CURRENT_BINARY_DIR}" "${CMAKE_CURRENT_LIST_DIR}/DotnetRunnerTests.csproj")