project("ADBench_DiffSharp")

add_custom_target(DiffSharpModule ALL
    COMMAND "dotnet" "publish" "--configuration" "${AD_BUILD_TYPE}" "--output" "${CMAKE_CURRENT_BINARY_DIR}" "-p:IntermediateOutputPath=${CMAKE_CURRENT_BINARY_DIR}/obj/" "${CMAKE_CURRENT_LIST_DIR}/DiffSharpModule.fsproj"
    )