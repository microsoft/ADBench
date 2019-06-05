project("ModuleTests")

# Get gtest package
hunter_add_package(GTest)
find_package(GTest CONFIG REQUIRED)
#find_package(GMock CONFIG REQUIRED)

if(NOT EXISTS "${GTest_LICENSES}")
  message(FATAL_ERROR "File not found: '${GTest_LICENSES}")
endif()
message("License file: '${GTest_LICENSES}'")

add_subdirectory ("cpp/manual")
