project("JacobianComparisonLibTests")

add_custom_target(JacobianComparisonLibTests ALL
    COMMAND "dotnet" "build" "--configuration" "${AD_BUILD_TYPE}" "--output" "${CMAKE_CURRENT_BINARY_DIR}" "-p:IntermediateOutputPath=${CMAKE_CURRENT_BINARY_DIR}/obj/" "${CMAKE_CURRENT_LIST_DIR}/JacobianComparisonLibTests.csproj"
    )

# TODO: Maybe, write automatic discovery instead of dumping all tests into one.
add_test(
    NAME TestJacobianComparisonLib
    COMMAND "dotnet" "test" "--no-build" "--configuration" "${AD_BUILD_TYPE}" "--output" "${CMAKE_CURRENT_BINARY_DIR}" "${CMAKE_CURRENT_LIST_DIR}/JacobianComparisonLibTests.csproj")