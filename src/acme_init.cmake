include(${CMAKE_CURRENT_LIST_DIR}/consts.cmake)

if(NOT ARG2)
	file(READ ${CMAKE_CURRENT_LIST_DIR}/acme_init_help.txt v)
	message(${v})
	return()
endif()

list(GET ARGS 0 path)
list(REMOVE_AT ARGS 0)

unset(next_arg)
foreach(i ${ARGS})
	if(next_arg)
		if(next_arg STREQUAL package-name)
			set(package_name ${i})
		else()
			message(FATAL_ERROR "Invalid next_arg: ${next_arg}")
		endif()
		unset(next_arg)
	else()
		if(i STREQUAL -x OR i STREQUAL --exe)
			set(f_exe 1)
		elseif(i STREQUAL -l OR i STREQUAL --lib)
			set(f_lib 1)
		elseif(i STREQUAL -a OR i STREQUAL --static)
			set(f_static 1)
		elseif(i STREQUAL -s OR i STREQUAL --shared)
			set(f_shared 1)
		elseif(i STREQUAL -m OR i STREQUAL --module)
			set(f_module 1)
		elseif(i STREQUAL -p OR i STREQUAL --package)
			set(next_arg package-name)
		else()
			message(FATAL_ERROR "Unknown option: ${i}")
		endif()
	endif()
endforeach()

if((f_shared AND f_static) OR (f_shared AND f_module) OR (f_static AND f_module))
	message(FATAL_ERROR "Specify only one of shared, static or module")
endif()

if(f_exe AND (f_lib OR f_static OR f_module OR f_shared))
	message(FATAL_ERROR "Specify either executable or library (shared/static/module)")
endif()

unset(ACME_SOURCE_PREFIX_VALID)
if(IS_DIRECTORY "$ENV{ACME_SOURCE_PREFIX}")
	set(ACME_SOURCE_PREFIX_VALID 1)
endif()

# path can be
# absolute, package name given
# absolute, package name relative to ACME_SOURCE_PREFIX
# relative to ACME_SOURCE_PREFIX, package name is same
# relative to CWD, package name is relative to ACME_SOURCE_PREFIX
# relative TO CWD, package name is given

if(package_name)
	set(package_name_was_specified 1)
endif()

if(IS_ABSOLUTE ${path})
	set(abs_path ${path})
else()
	# relative path given
	get_filename_component(abs_path ${path} ABSOLUTE)
endif()

# if not package name was given, it must be below ACME_SOURCE_PREFIX
if(NOT package_name AND ACME_SOURCE_PREFIX_VALID)

	# it can be relative to CWD, package name = relative to ACME_SOURCE_PREFIX
	file(RELATIVE_PATH rel_path $ENV{ACME_SOURCE_PREFIX} ${abs_path})
	string(REGEX MATCH ${ACME_REGEX_PACKAGE_NAME_SLASH} v ${rel_path})

	# or it can be relative to ACME_SOURCE_PREFIX
	set(abs_path2 $ENV{ACME_SOURCE_PREFIX}/${path})
	string(REGEX MATCH ${ACME_REGEX_PACKAGE_NAME_SLASH} v2 ${path})

	if(IS_DIRECTORY ${abs_path2} AND v2)
		if(IS_DIRECTORY ${abs_path} AND v)
			# both are valid, ambigous
			message(FATAL_ERROR "Ambigous relate path: <path> can be interpreted both relative to ACME_SOURCE_PREFIX and current directory.")
		else()
			set(abs_path ${abs_path2})
			string(REPLACE "/" "." package_name ${path})
		endif()
	else()
		if(IS_DIRECTORY ${abs_path} AND v)
			# only cwd-relative path is valid
			# nothing to do here
			string(REPLACE "/" "." package_name ${rel_path})
		else()
			# none are valid
			message(FATAL_ERROR "Path '${path} not found, tried as relative to ACME_SOURCE_PREFIX and to current directory.")
		endif()
	endif()
endif()

# validate package_name
if(NOT package_name)
	message(FATAL_ERROR "Specify a package name or set ACME_SOURCE_PREFIX to the root of the source package tree.")
endif()

string(REGEX MATCH ${ACME_REGEX_PACKAGE_NAME_DOT} v ${package_name})
if(NOT v)
	message("Invalid package name: '${package_name}'")
endif()

set(ACME_PACKAGE_NAME ${package_name})

if(NOT IS_DIRECTORY ${abs_path})
	message(FATAL_ERROR "Package directory does not exist: ${abs_path}")
endif()

if(f_exe)
	set(ACME_ADD_TARGET_MACRO acme_add_executable)
	unset(ACME_LIBRARY_TYPE)
elseif(f_lib OR f_module OR f_shared OR f_static)
	set(ACME_ADD_TARGET_MACRO acme_add_library)
	if(f_module)
		set(ACME_LIBRARY_TYPE MODULE)
	elseif(f_static)
		set(ACME_LIBRARY_TYPE STATIC)
	elseif(f_shared)
		set(ACME_LIBRARY_TYPE SHARED)
	else()
		unset(ACME_LIBRARY_TYPE)
	endif()
else()
	message(FATAL_ERROR "Either executable or a library must be specified")
endif()

message(STATUS "Initializing the package '${package_name}' at ${abs_path}")
if(EXISTS ${abs_path}/CMakeLists.txt)
	message(STATUS "Touch existing CMakelists.txt")
	file(APPEND ${abs_path}/CMakeLists.txt "") # touch
else()
	message(STATUS "Create CMakelists.txt")
	configure_file(${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt ${abs_path}/CMakeLists.txt @ONLY)
endif()

set(ACME_ROOT ${CMAKE_CURRENT_LIST_DIR}/..)
get_filename_component(ACME_ROOT ${ACME_ROOT} ABSOLUTE)

#refresh .acme directory
message(STATUS "Create .acme subdirectory")
if(EXISTS ${abs_path}/.acme)
	file(REMOVE_RECURSE ${abs_path}/.acme)
endif()

file(MAKE_DIRECTORY ${abs_path}/.acme)

file(GLOB vr RELATIVE ${ACME_ROOT} ${ACME_ROOT}/*)
foreach(i doc src test)
	file(GLOB_RECURSE v RELATIVE ${ACME_ROOT} ${ACME_ROOT}/${i}/*)
	list(APPEND vr ${v})
endforeach()

foreach(i ${vr})
	if(NOT IS_DIRECTORY "${ACME_ROOT}/${i}" AND NOT "${i}" STREQUAL "acme.config.cmake")
		configure_file(${ACME_ROOT}/${i} ${abs_path}/.acme/${i} COPYONLY)
	endif()
endforeach()


