project("PythonModuleCommonTests")

add_test(
    NAME PythonBaModuleCommonTests
    COMMAND ${Python3_EXECUTABLE} "${CMAKE_SOURCE_DIR}/test/python/modules/common/ba_tests.py")

add_test(
    NAME PythonGmmModuleCommonTests
    COMMAND ${Python3_EXECUTABLE} "${CMAKE_SOURCE_DIR}/test/python/modules/common/gmm_tests.py")

add_test(
    NAME PythonLstmModuleCommonTests
    COMMAND ${Python3_EXECUTABLE} "${CMAKE_SOURCE_DIR}/test/python/modules/common/lstm_tests.py")

add_test(
    NAME PythonHandModuleCommonTests
    COMMAND ${Python3_EXECUTABLE} "${CMAKE_SOURCE_DIR}/test/python/modules/common/hand_tests.py")