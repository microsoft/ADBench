project("JacobianComparisonLib")

add_custom_target(JacobianComparisonLib ALL
    COMMAND "dotnet" "build" "--configuration" "${AD_BUILD_TYPE}" "--output" "${CMAKE_CURRENT_BINARY_DIR}" "${CMAKE_CURRENT_LIST_DIR}/JacobianComparisonLib.csproj"
    COMMAND "${CMAKE_COMMAND}" -E remove_directory "${CMAKE_CURRENT_LIST_DIR}/obj"
    )