project(PyTorch)

execute_process(
    COMMAND ${Python3_EXECUTABLE} "-m" "pip" "install"
    "-r" "${CMAKE_CURRENT_SOURCE_DIR}/requirements.txt"
    "--find-links" "https://download.pytorch.org/whl/torch_stable.html"
    )