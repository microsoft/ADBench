project("ADBench_dotnet_Modules_Test")

add_custom_target(DotnetModulesTests ALL
    COMMAND "dotnet" "build" "--configuration" "${AD_BUILD_TYPE}" "--output" "${CMAKE_CURRENT_BINARY_DIR}" "-p:IntermediateOutputPath=${CMAKE_CURRENT_BINARY_DIR}/obj/" "${CMAKE_CURRENT_LIST_DIR}/DotnetModulesTests.csproj"
    )

add_dotnet_test("DotnetModulesTests" "DotnetModulesTests.csproj")