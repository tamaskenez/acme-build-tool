# load config
get_filename_component(ACME_DIR ${CMAKE_CURRENT_LIST_DIR}/.. ABSOLUTE)

if(IS_DIRECTORY "$ENV{ACME_ROOT}")
	set(ACME_ROOT "$ENV{ACME_ROOT}")
else()
	unset(ACME_ROOT)
endif()

# include default, global and local configs (if exist)

include(${ACME_DIR}/src/acme.config.default.cmake)

set(ACME_GLOBAL_CONFIG_FILE "${ACME_ROOT}/acme.config.cmake")
set(ACME_LOCAL_CONFIG_FILE "${CMAKE_CURRENT_SOURCE_DIR}/acme.config.cmake")

if(ACME_ROOT AND EXISTS "${ACME_GLOBAL_CONFIG_FILE}")
	include(${ACME_GLOBAL_CONFIG_FILE})
endif()

if(EXISTS "${ACME_LOCAL_CONFIG_FILE}")
	include(${ACME_LOCAL_CONFIG_FILE})
endif()

file(READ ${ACME_DIR}/version ACME_VERSION)
string(STRIP "${ACME_VERSION}" ACME_VERSION)

if("${ACME_VERSION}" STREQUAL "")
	message(FATAL_ERROR "Missing version in '${ACME_DIR}'")
endif()

unset(ACME_ROOT_VERSION)

# auto update
if(ACME_ROOT
	AND ACME_AUTO_UPDATE
	AND EXISTS "${ACME_ROOT}/version"
)
	file(READ ${ACME_ROOT}/version ACME_ROOT_VERSION)
	string(STRIP "${ACME_ROOT_VERSION}" ACME_ROOT_VERSION)
else()
	unset(ACME_ROOT_VERSION)
endif()

if(ACME_ROOT_VERSION AND ACME_ROOT_VERSION VERSION_GREATER ACME_VERSION)
	message("Updating ACME from ${ACME_ROOT}")
	message("Updating from version ${ACME_VERSION} to ${ACME_ROOT_VERSION}")

	file(REMOVE_RECURSE ${ACME_DIR})
	file(MAKE_DIRECTORY ${ACME_DIR})

	file(GLOB vr RELATIVE ${ACME_ROOT} ${ACME_ROOT}/*)
	foreach(i doc src test)
		file(GLOB_RECURSE v RELATIVE ${ACME_ROOT} ${ACME_ROOT}/${i}/*)
		list(APPEND vr ${v})
	endforeach()

	foreach(i ${vr})
		if(NOT IS_DIRECTORY "${ACME_ROOT}/${i}" AND NOT "${i}" STREQUAL "acme.config.cmake")
			configure_file(${ACME_ROOT}/${i} ${ACME_DIR}/${i} COPYONLY)
		endif()
	endforeach()

	include("${ACME_DIR}/src/init.cmake")
else()
	include(${CMAKE_CURRENT_LIST_DIR}/scripts.cmake)
endif()

