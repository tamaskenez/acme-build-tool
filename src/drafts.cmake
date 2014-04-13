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
