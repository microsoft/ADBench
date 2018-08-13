project("Tools-DiffSharp")

set(DIFFSHARP_CONFIGS "Debug-BA")

if (WIN32)
	foreach(config ${DIFFSHARP_CONFIGS})
		message("Running DiffSharpTests build.bat, config=${config}")
		execute_process(COMMAND "${CMAKE_CURRENT_LIST_DIR}/build.bat" "${CMAKE_CURRENT_LIST_DIR}" "${CMAKE_CURRENT_BINARY_DIR}" "${config}")
		message("Finished DiffSharpTests build.bat, config=${config}")
	endforeach(config)
endif()

# TODO support non-windows platforms
