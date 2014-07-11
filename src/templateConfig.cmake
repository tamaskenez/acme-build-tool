unset(@PREFIX@_LIBRARIES)
unset(@PREFIX@_INCLUDE_DIRS)
unset(@PREFIX@_DEFINITIONS)
unset(@PREFIX@_RUNTIME_LIBRARIES)
unset(@PREFIX@_RUNTIME_LIBRARY_DIRS)

# recover CMAKE_INSTALL_PREFIX
get_filename_component(@PREFIX@_INSTALL_PREFIX "${CMAKE_CURRENT_LIST_DIR}/@ACME_INSTALL_PREFIX_FROM_CONFIG_MODULE@" ABSOLUTE)

set(@PREFIX@_DEPENDENT_PACKAGES_PUBLIC @ACME_DEPENDENT_PACKAGES_PUBLIC@)

# private packages will be needed if this is a static library
set(@PREFIX@_DEPENDENT_PACKAGES_PRIVATE @ACME_DEPENDENT_PACKAGES_PRIVATE@)

# find_package args for the dependent packages
@ACME_CONFIG_MODULE_FIND_PACKAGE_ARGS@

unset(_errmsg)

while(1) # not real while, just scope for break()

	if(NOT "@_ACME_TARGET_TYPE@" MATCHES "^EXECUTABLE$")
		set(@PREFIX@_INCLUDE_DIRS ${@PREFIX@_INSTALL_PREFIX}/include)
		if(NOT IS_DIRECTORY ${@PREFIX@_INCLUDE_DIRS})
			set(_errmsg "Include dir: '${@PREFIX@_INCLUDE_DIRS}' not found")
			break()
		endif()

		find_library(@PREFIX@_LIBRARY_O @ACME_TARGET_NAME@ PATHS ${@PREFIX@_INSTALL_PREFIX}/lib NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH)
		find_library(@PREFIX@_LIBRARY_D @ACME_TARGET_NAME@@ACME_DEBUG_POSTFIX@ PATHS ${@PREFIX@_INSTALL_PREFIX}/lib NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH)
		mark_as_advanced(@PREFIX@_LIBRARY_O)
		mark_as_advanced(@PREFIX@_LIBRARY_D)

		if(@PREFIX@_LIBRARY_O)
			if(@PREFIX@_LIBRARY_D)
				list(APPEND @PREFIX@_LIBRARIES
					debug ${@PREFIX@_LIBRARY_D}
					optimized ${@PREFIX@_LIBRARY_O}
				)
			else()
				if(WIN32)
					list(APPEND @PREFIX@_LIBRARIES
						optimized ${@PREFIX@_LIBRARY_O}
						debug @PREFIX@_DEBUG_LIBRARY_NOT_FOUND
					)
				else()
					list(APPEND @PREFIX@_LIBRARIES
						${@PREFIX@_LIBRARY_O}
					)
				endif()
			endif()
		else()
			if(@PREFIX@_LIBRARY_D)
				list(APPEND @PREFIX@_LIBRARIES
					debug ${@PREFIX@_LIBRARY_D}
					optimized @PREFIX@_OPTIMIZED_LIBRARY_NOT_FOUND
				)
			else()
				set(_errmsg "Library '@ACME_TARGET_NAME@' not found in path '${@PREFIX@_INSTALL_PREFIX}/lib'")
				break()
			endif()
		endif()

		# collect runtime library components
		if(@_shared@)
			unset(@PREFIX@_RUNTIME_LIBRARY_O)
			unset(@PREFIX@_RUNTIME_LIBRARY_DIR_O)
			unset(@PREFIX@_RUNTIME_LIBRARY_D)
			unset(@PREFIX@_RUNTIME_LIBRARY_DIR_D)
			# search paths
			set(_ds
				${@PREFIX@_INSTALL_PREFIX}/@ACME_INSTALL_TARGETS_RUNTIME_DESTINATION@
				${@PREFIX@_INSTALL_PREFIX}/@ACME_INSTALL_TARGETS_LIBRARY_DESTINATION@
				)
			if(@PREFIX@_LIBRARY_O AND @_runtime_library_r@)
				foreach(_i ${_ds})
					set(_p "${_i}/@_runtime_library_r@")
					if(EXISTS ${_p})
						set(@PREFIX@_RUNTIME_LIBRARY_O ${_p})
						set(@PREFIX@_RUNTIME_LIBRARY_DIR_O ${_i})
						break()
					endif()
				endforeach()
				if(NOT @PREFIX@_RUNTIME_LIBRARY_O OR NOT @PREFIX@_RUNTIME_LIBRARY_DIR_O)
					set(_errmsg "Runtime component '@_runtime_library_r@' not found in paths: ${_ds}")
					break()
				endif()
			endif()
			if(@PREFIX@_LIBRARY_D AND @_runtime_library_d@)
				foreach(_i ${_ds})
					set(_p "${_i}/@_runtime_library_d@")
					if(EXISTS ${_p})
						set(@PREFIX@_RUNTIME_LIBRARY_D ${_p})
						set(@PREFIX@_RUNTIME_LIBRARY_DIR_D ${_i})
						break()
					endif()
				endforeach()
				if(NOT @PREFIX@_RUNTIME_LIBRARY_D OR NOT @PREFIX@_RUNTIME_LIBRARY_DIR_D)
					set(_errmsg "Runtime component '@_runtime_library_d@' not found in paths ${_ds}")
					break()
				endif()
			endif()
			set(@PREFIX@_RUNTIME_LIBRARIES ${@PREFIX@_RUNTIME_LIBRARY_O} ${@PREFIX@_RUNTIME_LIBRARY_D})
			set(@PREFIX@_RUNTIME_LIBRARY_DIRS ${@PREFIX@_RUNTIME_LIBRARY_DIR_O} ${@PREFIX@_RUNTIME_LIBRARY_DIR_D})
		endif()
	else()
		find_program(@PREFIX@_EXECUTABLE @ACME_TARGET_NAME@ PATHS ${@PREFIX@_INSTALL_PREFIX}/@ACME_INSTALL_TARGETS_RUNTIME_DESTINATION@ NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH)
		if(NOT @PREFIX@_EXECUTABLE)
			set(_errmsg "Program '@ACME_TARGET_NAME@' not found in path '${@PREFIX@_INSTALL_PREFIX}/@ACME_INSTALL_TARGETS_RUNTIME_DESTINATION@'")
			break()
		endif()
	endif()

	set(@PREFIX@_DEPENDENT_PACKAGES ${@PREFIX@_DEPENDENT_PACKAGES_PUBLIC})
	if(NOT @_shared@)
		set(@PREFIX@_DEPENDENT_PACKAGES ${@PREFIX@_DEPENDENT_PACKAGES_PUBLIC})
	end
	foreach(i ${@PREFIX@_DEPENDENT_PACKAGES_PUBLIC} ${@PREFIX@_DEPENDENT_PACKAGES_PRIVATE})
		find_package(${@PREFIX@_FIND_PACKAGE_${i}_ARGS} QUIET)
		if(NOT ${i}_FOUND)
			set(_errmsg "Dependency '${i}' not found")
		endif()
		list(APPEND @PREFIX@_RUNTIME_LIBRARY_DIRS ${${i}_RUNTIME_LIBRARY_DIRS})
		list(APPEND @PREFIX@_RUNTIME_LIBRARIES ${${i}_RUNTIME_LIBRARIES})

		if(@ACME_IS_LIBRARY@)
			list(GET @PREFIX@_DEPENDENT_PACKAGES_PUBLIC j ${i})
			if(NOT j EQUAL -1 # that package is public dependency
				OR NOT @_shared@) # or this is a static lib
				list(APPEND @PREFIX@_LIBRARIES ${${i}_LIBRARIES})
			endif()
			if(NOT j EQUAL -1) # that package is public dependency
				list(APPEND @PREFIX@_DEFINITIONS ${${i}_DEFINITIONS})
				list(APPEND @PREFIX@_INCLUDE_DIRS ${${i}_INCLUDE_DIRS})
			endif()
		endif()
	endforeach()

	if(_errmsg)
		break()
	endif()

	set(@PREFIX@_FOUND 1)

	break()
endwhile()

if(_errmsg)
	set(@PREFIX@_FOUND 0)
	unset(@PREFIX@_LIBRARIES)
	unset(@PREFIX@_INCLUDE_DIRS)
	unset(@PREFIX@_DEFINITIONS)
	unset(@PREFIX@_RUNTIME_LIBRARIES)
	unset(@PREFIX@_RUNTIME_LIBRARY_DIRS)

	if(@PREFIX@_FIND_REQUIRED)
		set(_w FATAL_ERROR)
	else()
		set(_w WARNING)
	endif()
	message(${_w} ${_errmsg})
endif()



