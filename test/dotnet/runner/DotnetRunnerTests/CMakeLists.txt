project("ADBench_dotnet_Runner_Test")

add_custom_target(DotnetRunnerTests ALL
    COMMAND "dotnet" "build" "--configuration" "${AD_BUILD_TYPE}" "--output" "${CMAKE_CURRENT_BINARY_DIR}" "-p:IntermediateOutputPath=${CMAKE_CURRENT_BINARY_DIR}/obj/" "${CMAKE_CURRENT_LIST_DIR}/DotnetRunnerTests.csproj"
    )

add_dotnet_test("DotnetRunnerTests" "DotnetRunnerTests.csproj")