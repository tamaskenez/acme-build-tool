
	macro(acme_generate_and_install_all_header ACME_ALL_HEADER_FILENAME)
		list(FIND ACME_PUBLIC_HEADER_FILES ${CMAKE_CURRENT_SOURCE_DIR}/${ACME_ALL_HEADER_FILENAME} _i)
		if(NOT _i EQUAL -1)
			message(WARNING "Skipping all-header generation because the source contains one with the same name (${ACME_ALL_HEADER_FILENAME})")
		else()
			unset(_l)
			foreach(_i ${ACME_PUBLIC_HEADER_FILES})
				acme_get_project_relative_path_components(${_i} _dir _filename)
				if("${_dir}" STREQUAL NOTFOUND)
					message(WARNING "External public header ${_i} not included in the '${ACME_ALL_HEADER_FILENAME}' header")
				else()
					if(_dir)
						set(_dir ${dir}/)
					endif()
					list(APPEND _l "#include \"${ACME_PACKAGE_NAME_SLASH}/${_dir}${_filename}\"\n")
				endif()
			endforeach()
			string(RANDOM _v)
			set(_v ${ACME_PACKAGE_NAME_SLASH}_INCLUDED_${_v})
			string(TOUPPER ${_v} _v)
			string(MAKE_C_IDENTIFIER ${_v} _v)
			file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/${ACME_ALL_HEADER_FILENAME}
				"#ifndef ${_v}\n#define ${_v}\n\n"
				${_l}
				"\n#endif\n")
			install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${ACME_ALL_HEADER_FILENAME} DESTINATION include/${ACME_PACKAGE_NAME_SLASH})
		endif()
	endmacro()

	# Install the files in ACME_PUBLIC_HEADER_FILES to CMAKE_INSTALL_PREFIX/path
	# where path is the package path (company/foo/bar) postfixed with
	# the relative path of the header in CMAKE_CURRENT_SOURCE_DIR
	# or CMAKE_CURRENT_BINARY_DIR
	# If the file is outside the two, it will be installed into CMAKE_INSTALL_PREFIX.
	function(acme_install_public_headers)
		foreach(i ${ACME_PUBLIC_HEADER_FILES})
			# normalize
			if(NOT IS_ABSOLUTE ${i})
				set(i ${CMAKE_CURRENT_SOURCE_DIR}/${i})
			endif()
			get_filename_component(i ${i} ABSOLUTE)

			acme_dictionary_get(ACME_PUBLIC_HEADERS_TO_DESTINATION_MAP ${i} dir)
			if(dir STREQUAL NOTFOUND)
				acme_get_project_relative_path_components(${i} dir name)
			endif()
			if(dir STREQUAL NOTFOUND)
				message("External public header ${i} will be installed to include/${ACME_PACKAGE_NAME_SLASH}")
				set(dir "")
			endif()
			install(FILES ${i} DESTINATION include/${ACME_PACKAGE_NAME_SLASH}/${dir})
		endforeach()
	endfunction()



	macro(acme_install_config_module)
		unset(ACME_CONFIG_MODULE_FIND_PACKAGE_ARGS)
		unset(ACME_DEPENDENT_PACKAGES_PUBLIC)
		unset(ACME_DEPENDENT_PACKAGES_PRIVATE)
		set(_name ${ACME_PACKAGE_NAME})
		if(ACME_TARGET_TYPE STREQUAL SHARED
			OR ACME_TARGET_TYPE STREQUAL MODULE)
		)
			set(_shared 1)
			get_target_property(v ${ACME_TARGET_NAME} LOCATION_Release)
			get_target_property(vd ${ACME_TARGET_NAME} LOCATION_Debug)
			unset(_runtime_library)
			unset(_runtime_library_d)
			if(v)
				get_filename_component(j ${v} NAME)
				set(APPEND _runtime_library ${j})
			endif()
			if(vd)
				get_filename_component(j ${vd} NAME)
				set(APPEND _runtime_library_d ${j})
			endif()
		else()
			set(_shared 0)
		endif()
		foreach(i ${ACME_FIND_PACKAGE_NAMES})
			set(s ${ACME_FIND_PACKAGE_${i}_SCOPE})
			if("${s}" STREQUAL "")
				set(s PRIVATE)
			endif()
			if(NOT s STREQUAL PRIVATE AND NOT s STREQUAL PUBLIC)
				message(FATAL_ERROR "find_package scope must be PUBLIC or PRIVATE")
			endif()
			list(APPEND ACME_DEPENDENT_PACKAGES_${s} ${i})
			set(ACME_CONFIG_MODULE_FIND_PACKAGE_ARGS "${ACME_CONFIG_MODULE_FIND_PACKAGE_ARGS}\nset(${_name}_FIND_PACKAGE_${i}_ARGS ${ACME_FIND_PACKAGE_${i}_ARGS})")
		endforeach()

		# the next line makes, for example "cmake" -> "../"
		file(RELATIVE_PATH ACME_INSTALL_PREFIX_FROM_CONFIG_MODULE /tmp/${ACME_CONFIG_MODULE_DESTINATION} /tmp)

		configure_file(${ACME_DIR}/src/templateConfig.cmake ${_name}Config.cmake.in @ONLY)
		install(
			FILES ${CMAKE_CURRENT_BINARY_DIR}/${_name}Config.cmake.in
			DESTINATION ${ACME_CONFIG_MODULE_DESTINATION}
			RENAME ${_name}Config.cmake)
	endmacro()

	macro(acme_add_public_header_core)
		if(NOT IS_ABSOLUTE ${entry})
			set(entry ${CMAKE_CURRENT_SOURCE_DIR}/${entry})
		endif()
		get_filename_component(entry ${entry} ABSOLUTE)

		if(NOT destination)
			# check if it's relative to a CMAKE_CURRENT_BINARY_DIR or CMAKE_CURRENT_SOURCE_DIR
			acme_get_project_relative_path_components(${entry} dir name)
			if(dir STREQUAL NOTFOUND)
				message(FATAL_ERROR "Invalid public header '${entry} it's not in current source or binary dir and no explicit DESTINATION was given")
				endif()
			set(destination ${dir})
		endif()

		acme_dictionary_set(ACME_PUBLIC_HEADERS_TO_DESTINATION_MAP ${entry} ${destination})
		list(APPEND ACME_PUBLIC_HEADER_FILES ${entry})
	endmacro()

	# acme_add_public_headers(FILES <file> [<file> ...] RELATIVE <dir>])
	# acme_add_public_headers(GLOB|GLOB_RECURSE <glob-expr> [<glob-expr>] [RELATIVE dir])
	# acme_add_public_headers(TAGGED RELATIVE dir)
	#
	# You can add files to the list of the public headers with
	# this function. The install location (thus the path it
	# can be accessed by the #include directives) is the relative
	# path from a base directory. An example:
	#
	# - there are 2 public headers: <current-source>/h1.h and <current-source>/foo/h2.h
	# - the base directory for both is <current-source>
	# - they will be installed to include/<package-path>/h1.h and include/<package-path>/foo/h2.h
	#
	# With the FILES keyword you can specify a file list. The RELATIVE keyword
	# specifies the base directory for the files. If it's omitted it will
	# be either the current source or binary dir depending on the location
	# of the file.
	#
	# The GLOB and GLOB_RECURSE work as in the CMake function. Omitting the RELATIVE
	# keyword have the same effect as the previous FILE signature.
	#
	# The TAGGED signature has effect on the install location of the
	# files tagged with the `//#acme public header` or `/*#acme public header*/ macro.
	# By default their base directory is the current source dir. With this function
	# you can add additional base directories. For a given file the nearest base
	# directory will have effect.
	#
	# Relative file paths will be interpreted relative to current source dir.
	#
	# You can mix the FILES/GLOB/GLOB_RECURSE/TAGGED signatures. You can
	# specify multiple ones from each.
	#
	# Note on selecting the base directories. For clients of a library
	# the library's public headers must be accessed by full package path:
	#
	# #include "company/foo/bar/h1.h"
	#
	# The same header accessed from withing the library 'company.foo.bar':
	#
	# #include "h1.h"
	#
	# Both #include lines need to have the appropriate include_directories()
	# (-I compiler option) defined.
	#
	# However when multiple projects are combined in a superproject when
	# building the superproject the headers of company.foo.bar will not be installed by
	# the time its clients need it. So it must be accessed from the source
	# tree. The problem is that they are trying to use full paths in their
	# #include lines.
	#
	# In order to be able to add the appropriate include directories
	#
	# - the source tree of the library company.foo.bar must reside below
	#   the path company/foo/bar. The target company.foo.bar will be added
	#   a directory in its INTERFACE_INCLUDE_DIRECTORIES target property
	#   to the parent of company/foo/bar.
	# - or the library should be in a directory company.foo.bar. The
	#   clients' #include lines will be automatically rewritten by their
	#   acme scripts to #include "company.foo.bar/h1" and the parent
	#   dir will be added to INTERFACE_INCLUDE_DIRECTORIES.
	#
	# However we need to keep the following rules in order to be able to
	# support inclusion in superprojects:
	#
	# - The only header base directories should be the current source dir
	#   and the current binary dir
	# - Both should be placed in a hierarchy by the package name or
	#   they must be named as the package is (dot-separated)
	function(acme_add_public_headers)
		set(multiarg_modes FILES;GLOB;GLOB_RECURSE)
		set(argless_modes TAGGED)
		set(modes ${multiarg_modes} ${argless_modes})
		cmake_parse_arguments(
			APH
			TAGGED
			RELATIVE
			"${modes}"
			${ARGN})
		unset(mode)
		foreach(i ${modes})
			if(APH_${i})
				list(APPEND mode ${i})
			endif()
		endforeach()
		list(LENGTH mode l)
		if(NOT l EQUAL 1)
			message(FATAL_ERROR "Specify exactly one of these keywords: ${modes}")
		endif()

		if(APH_RELATIVE)
			acme_make_absolute_source_filename(APH_RELATIVE)
		endif()

		if(${mode} STREQUAL GLOB OR ${mode} STREQUAL "GLOB_RECURSE")
			file(${mode} APH_FILES ${APH_${mode}})
			acme_remove_acme_dir_files(APH_FILES)
			set(mode FILES)
		endif()

		if(${mode} STREQUAL FILES)
			foreach(i ${APH_FILES})
				acme_make_absolute_source_filename(i)
				if(APH_RELATIVE)
					string(FIND "${i}" "${APH_RELATIVE}" idx)
					if(NOT idx EQUAL 0)
						message(FATAL_ERROR "Public header ${i} is not in the specified base directory ${APH_RELATIVE}")
					endif()
					set(base_dir "${APH_RELATIVE}")
					file(RELATIVE_PATH dest_dir "${APH_RELATIVE}" "${i}")
				else()
					acme_get_project_relative_path_components(${i} dest_dir name_out base_dir)
					if(dest_dir STREQUAL NOTFOUND)
						message(FATAL_ERROR "Public header ${i} should be either in the current source or binary dir if no RELATIVE path is given.")
					endif()
				endif()
				list(APPEND ACME_PUBLIC_HEADER_FILES ${i})
				acme_dictionary_set(ACME_PUBLIC_HEADERS_TO_DESTINATION_MAP ${i} ${dest_dir})
				list(APPEND ACME_PUBLIC_HEADER_BASE_DIRS ${base_dir})
			endforeach()
		elseif(${mode} STREQUAL TAGGED)
			if(NOT APH_RELATIVE)
				message("TAGGED: missing RELATIVE argument")
			endif()
			acme_make_absolute_source_filename(APH_RELATIVE)
			list(APPEND ACME_PUBLIC_HEADER_TAGGED_BASE_DIRS "${APH_RELATIVE}")
		else()
			message(FATAL_ERROR "Invalid keyword: ${mode}")
		endif()
		set(ACME_PUBLIC_HEADERS_TO_DESTINATION_MAP_KEYS ${ACME_PUBLIC_HEADERS_TO_DESTINATION_MAP_KEYS} PARENT_SCOPE)
		set(ACME_PUBLIC_HEADERS_TO_DESTINATION_MAP_VALUES ${ACME_PUBLIC_HEADERS_TO_DESTINATION_MAP_VALUES} PARENT_SCOPE)
		set(ACME_PUBLIC_HEADER_FILES ${ACME_PUBLIC_HEADER_FILES} PARENT_SCOPE)
		set(ACME_PUBLIC_HEADER_BASE_DIRS ${ACME_PUBLIC_HEADER_BASE_DIRS} PARENT_SCOPE)
	endfunction()

	# acme_add_public_header(
	#	<file1> [DESTINATION <destdir1>]
	#	<file1> [DESTINATION <destdir2>])
	#
	# Add files as public headers.
	# In addition to files marked with #acme public header
	# you can also add files with this function.
	# Relative paths are interpreted relative to the current
	# source directory.
	# The optional DESTINATION argument specifies the relative directory
	# the header should be installed to. It is relative to
	# ${CMAKE_INSTALL_PREFIX}/include/${ACME_PACKAGE_NAME_SLASH}
	# e.g. if the package is company.foo.bar then a header with no destination
	# will be installed to include/company/foo/bar/ and if you specify
	# a DESTINATION it will be postfixed to that path
	# If no destination is given the destination will be the relative path from
	# either CMAKE_CURRENT_SOURCE_DIR or CMAKE_CURRENT_BINARY_DIR depending
	# on the location of the header. If it is outside of those directories
	# a FATAL_ERROR will be issued.
	function(acme_add_public_header)
		unset(destination)
		unset(entry)
		foreach(i ${ARGV})
			if(NOT entry)
				set(entry ${i})
			else()
				if(destination)
					set(destination ${i})
					acme_add_public_header_core()
					unset(entry)
					unset(destination)
				elseif("${i}" STREQUAL DESTINATION)
					set(destination 1)
				else()
					acme_add_public_header_core()
					set(entry ${i})
				endif()
			endif()
		endforeach()
		if(destination)
			message(FATAL_ERROR "Missing argument for DESTINATION")
		endif()
		if(entry)
			acme_add_public_header_core()
		endif()
		set(ACME_PUBLIC_HEADERS_TO_DESTINATION_MAP_KEYS ${ACME_PUBLIC_HEADERS_TO_DESTINATION_MAP_KEYS} PARENT_SCOPE)
		set(ACME_PUBLIC_HEADERS_TO_DESTINATION_MAP_VALUES ${ACME_PUBLIC_HEADERS_TO_DESTINATION_MAP_VALUES} PARENT_SCOPE)
		set(ACME_PUBLIC_HEADER_FILES ${ACME_PUBLIC_HEADER_FILES} PARENT_SCOPE)
	endfunction()

	function(acme_set_interface_properties)
		foreach(i ${ACME_FIND_PACKAGE_NAMES})
			if(${ACME_FIND_PACKAGE_${i}_SCOPE} STREQUAL PUBLIC)
				foreach(j ${i}_DEFINITIONS)
					string(FIND "${j}" "/D" idx1)
					string(FIND "${j}" "-D" idx2)
					if(idx1 EQUAL 0 OR idx2 EQUAL 0)
						string(SUBTRING "${j}" 2 -1 k)
						set_property(TARGET ${ACME_TARGET_NAME}
							APPEND PROPERTY INTERFACE_COMPILE_DEFINITIONS
							"${k}"
						)
					else()
						set_property(TARGET ${ACME_TARGET_NAME}
							APPEND PROPERTY INTERFACE_COMPILE_OPTIONS
							"${j}"
						)
					endif()
				endforeach()
				foreach(j ${i}_INCLUDE_DIRS)
					set_property(TARGET ${ACME_TARGET_NAME}
						APPEND PROPERTY INTERFACE_INCLUDE_DIRECTORIES
						"${j}"
					)
				endforeach()
			endif()
			if(ACME_TARGET_TYPE STREQUAL STATIC OR ${ACME_FIND_PACKAGE_${i}_SCOPE} STREQUAL PUBLIC)
			endif()
		endforeach()
	endfunction()

	macro(acme_add_target_and_install_all)
		acme_add_target(${ACME_TARGET_TYPE} ${ACME_TARGET_NAME}
			${ACME_SOURCE_AND_HEADER_FILES}
		)

		target_link_libraries(${ACME_TARGET_NAME}
			${ACME_FIND_PACKAGE_LIBRARIES})

		install(TARGETS ${ACME_TARGET_NAME}
			RUNTIME DESTINATION ${ACME_INSTALL_TARGETS_RUNTIME_DESTINATION}
			ARCHIVE DESTINATION ${ACME_INSTALL_TARGETS_ARCHIVE_DESTINATION}
			LIBRARY DESTINATION ${ACME_INSTALL_TARGETS_LIBRARY_DESTINATION})

		if(ACME_IS_LIBRARY)
			acme_set_interface_properties()
		endif()

		set_property(TARGET ${ACME_TARGET_NAME}
			APPEND/APPEND_STRING
			PROPERTY INTERFACE_LINK_LIBRARIES
		)

		# Installs public headers keeping source directory structure
		acme_install_public_headers()

		# Generates and installs config module
		acme_install_config_module()
	endmacro()


	# remove duplicates from a libraries listing
	# handles debug/optimized/general keywords
	function(acme_remove_duplicate_libraries _list_var)
		unset(_d)
		unset(_g)
		unset(_o)
		foreach(i ${${_list_var}})
			if(i STREQUAL debug)
				set(_s debug)
			elseif(i STREQUAL optimized)
				set(_s optimized)
			elseif(i STREQUAL general)
				unset(_s)
			else()
				if(NOT _s)
					list(APPEND _g ${i})
				elseif(_s STREQUAL debug)
					list(APPEND _d ${i})
				elseif(_s STREQUAL optimized)
					list(APPEND _o ${i})
				else()
					message(FATAL_ERROR "Invalid _s: ${_s}")
				endif()
				unset(_s)
			endif()
		endforeach()
		if(_d)
			list(REMOVE_DUPLICATES _d)
		endif()
		if(_o)
			list(REMOVE_DUPLICATES _o)
		endif()
		if(_g)
			list(REMOVE_DUPLICATES _g)
		endif()
		set(_l ${_g})
		foreach(i ${_d})
			list(APPEND _l debug ${i})
		endforeach()
		foreach(i ${_o})
			list(APPEND _l optimized ${i})
		endforeach()
		set(${_list_var} "${_l}" PARENT_SCOPE)
	endfunction()





endif()

