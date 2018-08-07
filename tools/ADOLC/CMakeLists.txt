
project("Tools-ADOLC")

hunter_add_package(Boost)
find_package(Boost CONFIG REQUIRED)

message(${BOOST_INCLUDE_DIRS})

# TODO use execute_process here to run build.bat (also add to it with boost and decent paths, etc.)

#add_executable("Tools-ADOLC-GMM" "main.cpp" "include/adolc/adolc.h")
#target_compile_definitions("Tools-ADOLC-GMM" PUBLIC "DO_GMM_FULL" "DO_CPP")
#target_include_directories("Tools-ADOLC-GMM" PRIVATE "${CMAKE_CURRENT_LIST_DIR}/include")
#target_link_libraries("Tools-ADOLC-GMM" "${CMAKE_CURRENT_LIST_DIR}/lib/adolc.lib")

#file(COPY "${CMAKE_CURRENT_LIST_DIR}/../cpp-common/bin/adolc.dll" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")

#add_executable("Tools-ADOLC-BA" "main.cpp" "include/adolc/adolc.h")
#target_compile_definitions("Tools-ADOLC-BA" PUBLIC "DO_BA_BLOCK" "DO_CPP")
#target_include_directories("Tools-ADOLC-BA" PRIVATE "${CMAKE_CURRENT_LIST_DIR}/include")
#target_link_libraries("Tools-ADOLC-BA" "${CMAKE_CURRENT_LIST_DIR}/lib/adolc.lib")
