project(TorchScript)

execute_process(
    COMMAND ${Python3_EXECUTABLE} "-m" "pip" "install"
    "-r" "${CMAKE_CURRENT_SOURCE_DIR}/requirements-shared.txt"
    )

# default option
option(CUDA OFF)

if (CUDA)
    execute_process(
        COMMAND ${Python3_EXECUTABLE} "-m" "pip" "install"
        "-r" "${CMAKE_CURRENT_SOURCE_DIR}/requirements-cuda.txt"
        "--find-links" "https://download.pytorch.org/whl/torch_stable.html"
        )
else()
    execute_process(
        COMMAND ${Python3_EXECUTABLE} "-m" "pip" "install"
        "-r" "${CMAKE_CURRENT_SOURCE_DIR}/requirements-noncuda.txt"
        "--find-links" "https://download.pytorch.org/whl/torch_stable.html"
        )
endif()