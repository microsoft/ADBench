project("ADBench_test_dotnet")

function(add_dotnet_test TEST_NAME PROJECT_FILE)
    add_test(
        NAME "${TEST_NAME}"
        COMMAND "dotnet" "test" "--no-build" "--configuration" "${AD_BUILD_TYPE}" "--output" "${CMAKE_CURRENT_BINARY_DIR}" "--logger" "trx;LogFileName=${CMAKE_BINARY_DIR}/Testing/${TEST_NAME}.trx" "${CMAKE_CURRENT_LIST_DIR}/${PROJECT_FILE}")
endfunction(add_dotnet_test)

add_subdirectory ("modules")
add_subdirectory ("runner")
add_subdirectory ("utils")