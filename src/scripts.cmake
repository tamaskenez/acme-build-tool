# code for experiments, not used in production

# acme_target_link_libraries for a single package from a previous
# acme_find_package or find_package call
function(acme_target_link_libraries_single_package _target_name _package_name _scope)
	if("${_scope}" STREQUAL "")
		set(_scope ACME_FIND_PACKAGE_${_package_name}_SCOPE)
	endif()
	if("${_scope}" STREQUAL "")
		set(_scope PRIVATE)
	endif()

	string(TOUPPER "${_package_name}" package_name_upper) # upper case package name
	if(${package_name_upper}_FOUND) # use upper case, if set
		set(prefix ${package_name_upper})
	else()
		set(prefix ${_package_name})
	endif()

	target_include_directories("${_target_name}" ${_scope} ${${prefix}_INCLUDE_DIRS})
	target_link_libraries("${_target_name}" ${_scope} ${${prefix}_LIBRARIES})

	foreach(i ${${prefix}_DEFINITIONS})
		string(FIND "${i}" "/D" idx1)
		string(FIND "${i}" "-D" idx2)
			if(idx1 EQUAL 0 OR idx2 EQUAL 0)
				string(SUBTRING "${i}" 2 -1 k)
				target_link_compile_definitions("${_target_name}" ${_scope} "${k}")
			else()
				target_link_compile_options("${_target_name}" ${_scope} "${i)")
			endif()
	endforeach()
endfunction()

# acme_target_link_libraries for a given scope
function(acme_target_link_libraries_scope targe_name scope)
	unset(config)
	foreach(i ${ARGN})
	endforeach()
endfunction()

# acme_target_link_libraries(<target_name>
#	[[PUBLIC|PRIVATE] <item> <item> ...])
# calls target_link_libraries with the items, plus
# - if the item is a package from a previous find_package
#   or acme_find_package call then it behaves as if there were
#   an imported target with the same name: the target_link_libraries,
#   target_include_directories, target_compile_definitions and
#   target_compile_options will be called with the appropriate values
function(acme_target_link_libraries target_name)
	set(scope PUBLIC) # default scope is public
	unset(v)
	foreach(i ${ARGN})
		if("${i}" STREQUAL PUBLIC)
			acme_target_link_libraries_mode(${target_name} ${scope} ${v})
			set(scope PUBLIC)
		elseif("${i}" STREQUAL PRIVATE)
			acme_target_link_libraries_mode(${target_name} ${scope} ${v})
			set(scope PRIVATE)
		else()
			list(APPEND v ${i})
		endif()
	endforeach()
	acme_target_link_libraries_mode(${target_name} ${scope} ${v})
endfunction()

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

