project("ADBench_test_dotnet_runner")

add_subdirectory ("DotnetRunnerTests")
add_subdirectory ("MockTest")
add_dependencies("DotnetRunnerTests" "MockTest")