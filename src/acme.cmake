# the command-line acme command (usually invoked from the acme shell script in parent directory)

cmake_minumum_required(VERSION 2.8.12)

set(ARGS ${ARG2} ${ARG3} ${ARG4} ${ARG5} ${ARG6})
if(ARG1 STREQUAL "init")
	include(${CMAKE_CURRENT_LIST_DIR}/acme_init.cmake)
else()
	if(NOT ARG1)
		message("Usage:")
		message("    acme <command>")
		message("The available commands are:")
		message("    init")
	else()
		message("Unknown command: '${ARG1}'.")
		message("Enter <acme> for help.")
	endif()
endif()
