
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

