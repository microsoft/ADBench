project("PythonModuleCommonTests")

add_test(
    NAME PythonBaModuleCommonTests
    COMMAND "python" "${CMAKE_SOURCE_DIR}/test/python/modules/common/ba_tests.py")

add_test(
    NAME PythonGmmModuleCommonTests
    COMMAND "python" "${CMAKE_SOURCE_DIR}/test/python/modules/common/gmm_tests.py")

add_test(
    NAME PythonLstmModuleCommonTests
    COMMAND "python" "${CMAKE_SOURCE_DIR}/test/python/modules/common/lstm_tests.py")

add_test(
    NAME PythonHandModuleCommonTests
    COMMAND "python" "${CMAKE_SOURCE_DIR}/test/python/modules/common/hand_tests.py")