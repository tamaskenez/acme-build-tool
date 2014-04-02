unset(@_name@_LIBRARIES)
unset(@_name@_INCLUDE_DIRS)
unset(@_name@_DEFINITIONS)
unset(@_name@_RUNTIME_LIBRARIES)
unset(@_name@_RUNTIME_LIBRARY_DIRS)

set(@_name@_INSTALL_PREFIX ${CMAKE_CURRENT_LIST_DIR}/@ACME_INSTALL_PREFIX_FROM_CONFIG_MODULE@)
get_filename_component(@_name@_INSTALL_PREFIX ${@_name@_INSTALL_PREFIX} ABSOLUTE)

set(@_name@_DEPENDENT_PACKAGES_PUBLIC @ACME_DEPENDENT_PACKAGES_PUBLIC@)
set(@_name@_DEPENDENT_PACKAGES_PRIVATE @ACME_DEPENDENT_PACKAGES_PRIVATE@)

@ACME_CONFIG_MODULE_FIND_PACKAGE_ARGS@

unset(_errmsg)

while(1) # not real while, just scope for break()

	if(@ACME_IS_LIBRARY@)
		set(@_name@_INCLUDE_DIRS ${@_name@_INSTALL_PREFIX}/include)
		if(NOT IS_DIRECTORY ${@_name@_INCLUDE_DIRS})
			set(_errmsg "Include dir: '${@_name@_INCLUDE_DIRS}' not found")
			break()
		endif()

		find_library(@_name@_LIBRARY @ACME_TARGET_NAME@ PATHS ${@_name@_INSTALL_PREFIX}/lib NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH)
		find_library(@_name@_LIBRARY_D @ACME_TARGET_NAME@@ACME_DEBUG_POSTFIX@ PATHS ${@_name@_INSTALL_PREFIX}/lib NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH)
		mark_as_advanced(@_name@_LIBRARY)
		mark_as_advanced(@_name@_LIBRARY_D)

		if(NOT @_name@_LIBRARY)
			set(_errmsg "Library '@ACME_TARGET_NAME@' not found in path '${@_name@_INSTALL_PREFIX}/lib'")
			break()
		endif()

		if(WIN32 AND NOT @_name@_LIBRARY_D)
			message(WARNING "Debug library not found, on win32 this may cause problems because of the different runtime libraries.")
		endif()

		if(@_name@_LIBRARY_D)
			list(APPEND @_name@_LIBRARIES
				debug ${@_name@_LIBRARY_D}
				optimized ${@_name@_LIBRARY}
			)
		else()
			list(APPEND @_name@_LIBRARIES
				${@_name@_LIBRARY}
			)
		endif()

		# collect runtime library components
		if(@_shared@)
			unset(@_name@_RUNTIME_LIBRARY)
			unset(@_name@_RUNTIME_LIBRARY_DIR)
			unset(@_name@_RUNTIME_LIBRARY_D)
			unset(@_name@_RUNTIME_LIBRARY_DIR_D)
			# search paths
			set(_ds ${@_name@_INSTALL_PREFIX}/lib ${@_name@_INSTALL_PREFIX}/bin)
			if(NOT "@_runtime_library@" STREQUAL "")
				foreach(_i ${_ds})
					set(_p "${_i}/@_runtime_library@")
					if(EXISTS ${_p})
						set(@_name@_RUNTIME_LIBRARY ${_p})
						set(@_name@_RUNTIME_LIBRARY_DIR ${_i})
						break()
					endif()
				endforeach()
				if(NOT @_name@_RUNTIME_LIBRARY OR NOT @_name@_RUNTIME_LIBRARY_DIR)
					set(_errmsg "Runtime component '@_runtime_library@' not found in paths ${_ds}")
					break()
				endif()
			endif()
			if(@_name@_LIBRARY_D AND NOT "@_runtime_library_d@" STREQUAL "")
				foreach(_i ${_ds})
					set(_p "${_i}/@_runtime_library_d@")
					if(EXISTS ${_p})
						set(@_name@_RUNTIME_LIBRARY_D ${_p})
						set(@_name@_RUNTIME_LIBRARY_DIR_D ${_i})
						break()
					endif()
				endforeach()
				if(NOT @_name@_RUNTIME_LIBRARY_D OR NOT @_name@_RUNTIME_LIBRARY_DIR_D)
					set(_errmsg "Runtime component '@_runtime_library_d@' not found in paths ${_ds}")
					break()
				endif()
			endif()
			set(@_name@_RUNTIME_LIBRARIES ${@_name@_RUNTIME_LIBRARY} ${@_name@_RUNTIME_LIBRARY_D})
			set(@_name@_RUNTIME_LIBRARY_DIRS ${@_name@_RUNTIME_LIBRARY_DIR} ${@_name@_RUNTIME_LIBRARY_DIR_D})
		endif()
	else()
		find_program(@_name@_EXECUTABLE @ACME_TARGET_NAME@ PATHS ${@_name@_INSTALL_PREFIX}/bin NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH)
		if(NOT @_name@_EXECUTABLE)
			set(_errmsg "Program '@ACME_TARGET_NAME@' not found in path '${@_name@_INSTALL_PREFIX}/bin'")
			break()
		endif()
	endif()

	foreach(i ${@_name@_DEPENDENT_PACKAGES_PUBLIC} ${@_name@_DEPENDENT_PACKAGES_PRIVATE})
		find_package(${@_name@_FIND_PACKAGE_${i}_ARGS} QUIET)
		if(NOT ${i}_FOUND)
			set(_errmsg "Dependency '${i}' not found")
		endif()
		list(APPEND @_name@_RUNTIME_LIBRARY_DIRS ${${i}_RUNTIME_LIBRARY_DIRS})
		list(APPEND @_name@_RUNTIME_LIBRARIES ${${i}_RUNTIME_LIBRARIES})

		if(@ACME_IS_LIBRARY@)
			list(GET @_name@_DEPENDENT_PACKAGES_PUBLIC j ${i})
			if(NOT j EQUAL -1 # that package is public dependency
				OR NOT @_shared@) # or this is a static lib
				list(APPEND @_name@_LIBRARIES ${${i}_LIBRARIES})
			endif()
			if(NOT j EQUAL -1) # that package is public dependency
				list(APPEND @_name@_DEFINITIONS ${${i}_DEFINITIONS})
				list(APPEND @_name@_INCLUDE_DIRS ${${i}_INCLUDE_DIRS})
			endif()
		endif()
	endforeach()

	if(_errmsg)
		break()
	endif()

	set(@_name@_FOUND 1)

	break()
endwhile()

if(_errmsg)
	set(@_name@_FOUND 0)
	unset(@_name@_LIBRARIES)
	unset(@_name@_INCLUDE_DIRS)
	unset(@_name@_DEFINITIONS)
	unset(@_name@_RUNTIME_LIBRARIES)
	unset(@_name@_RUNTIME_LIBRARY_DIRS)

	if(@_name@_FIND_REQUIRED)
		set(_w FATAL_ERROR)
	else()
		set(_w WARNING)
	endif()
	message(${_w} ${_errmsg})
endif()



