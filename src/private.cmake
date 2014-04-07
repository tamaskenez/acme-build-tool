# private functions and macros to be used by public_api.cmake

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

# acme_process_add_target_unprocessed_args(<files_var_out> <globs_var_out> <glob_recurses_var_out>
#	<arg1> <arg> ... FILES ... GLOB ... GLOB_RECURSE ...)
# collect the items in the tail list:
# the first items and items after FILES go into files_var_out
# items after GLOB go into globs_var_out
# items after GLOB_RECURSE go into glob_recurses_var_out
function(acme_process_add_target_unprocessed_args files_var_out globs_var_out glob_recurses_var_out)
	unset(files_out)
	unset(globs_out})
	unset(glob_recurses_out})
	set(varname files_out)
	foreach(i ${ARGN})
		if("${i}" STREQUAL FILES)
			set(varname files_out)
		elseif("${i}" STREQUAL GLOB)
			set(varname globs_out)
		elseif("${i}" STREQUAL GLOB_RECURSE)
			set(varname glob_recurses_out)
		else()
			list(APPEND ${varname} "${i}")
		endif()
	endforeach()
	set(${files_var_out} ${files_out} PARENT_SCOPE)
	set(${globs_var_out} ${globs_out} PARENT_SCOPE)
	set(${glob_recurses_var_out} ${glob_recurses_out} PARENT_SCOPE)
endfunction()

# acme_remove_acme_dir_files(files_var_inout)
# Removes the files from the list which are in the ${CMAKE_CURRENT_SOURCE_DIR}/.acme
# Expects absolute paths
function(acme_remove_acme_dir_files files_var_inout)
	set(files_inout ${${files_var_inout}})
	unset(v)
	foreach(i ${files_inout})
		if(NOT IS_ABSOLUTE "${i}")
			message(FATAL_ERROR "Internal error, this function expects absolute paths.")
		endif()
		string(FIND "${i}" "${CMAKE_CURRENT_SOURCE_DIR}/.acme" idx)
		if(NOT idx EQUAL 0)
			list(APPEND v ${i})
		endif()
	endforeach()
	set(${files_var_inout} ${v} PARENT_SCOPE)
endfunction()

# acme_append_files_with_globbers(files_var_inout glob_var_in glob_recurse_var_in)
# - performs the GLOB and GLOB_RECURSE operations for the lists in the
#   glob_var, glob_recurse_var
# - filters out files from .acme subdirectory of the CMAKE_CURRENT_SOURCE_DIR
# - appends the globbed files to files_var_inout
function(acme_append_files_with_globbers files_var_inout glob_var_in glob_recurse_var_in)
	set(_afwg_files_in ${${files_var_inout}})
	file(GLOB _afwg_v1 ${${glob_var_in}})
	file(GLOB_RECURSE _afwg_v2 ${${glob_recurse_var_in}})
	set(v ${_afwg_v1} ${_afwg_v2})
	acme_remove_acme_dir_files(v)
	set(${files_var_inout} ${_afwg_files_in} ${v} PARENT_SCOPE)
endfunction()

# acme_get_project_relative_path_components(path_in dir_out name_out [base_dir_out])
# Return the relative path of a file to the project.
# 
# If the input par 'path_in' is relative, it is interpreted relative to
# CMAKE_CURRENT_SOURCE_DIR.
#
# The output parameter 'dir_out' contains
# the relative directory to either the CMAKE_CURRENT_SOURCE_DIR
# or CMAKE_CURRENT_BINARY_DIR, depending on the location of the file.
#
# The output parameter name_out contains the file name component.
#
# If the file's location is outside of those directories,
# 'dir_out' will be NOTFOUND
function(acme_get_project_relative_path_components path_in dir_out name_out)
	if("${path_in}" STREQUAL "")
		message(FATAL_ERROR "invalid input: empty path)")
	endif()

	if(NOT IS_ABSOLUTE ${path_in})
		set(path_in ${CMAKE_CURRENT_SOURCE_DIR}/${path_in})
	endif()

	# normalize absolute path
	get_filename_component(path_in ${path_in} ABSOLUTE)

	if(path_in STREQUAL ${CMAKE_CURRENT_SOURCE_DIR} OR
		path_in STREQUAL ${CMAKE_CURRENT_BINARY_DIR})
		message(FATAL_ERROR "invalid input: path equals to current source or binary dir, there's no filename appended (path = ${path_in})")
	endif()

	string(FIND ${path_in} ${CMAKE_CURRENT_SOURCE_DIR} ss)
	unset(root)
	if(ss EQUAL 0)
		set(root ${CMAKE_CURRENT_SOURCE_DIR})
	endif()
	if(NOT root)
		string(FIND ${path_in} ${CMAKE_CURRENT_BINARY_DIR} ss)
		if(ss EQUAL 0)
			set(root ${CMAKE_CURRENT_BINARY_DIR})
		endif()
	endif()
	if(root)
		file(RELATIVE_PATH relpath ${root} ${path_in})
		get_filename_component(local_dir_out ${relpath} PATH)
		get_filename_component(local_name_out ${relpath} NAME)
		set(${dir_out} "${local_dir_out}" PARENT_SCOPE)
	else()
		set(${dir_out} NOTFOUND PARENT_SCOPE)
		get_filename_component(local_name_out ${path_in} NAME)
	endif()
	if(ARGV3)
		set(${ARGV3} ${root} PARENT_SCOPE)
	endif()
	set(${name_out} ${local_name_out} PARENT_SCOPE)
endfunction()

# make relative file names absolute by prefixing with CMAKE_CURRENT_SOURCE_DIR
# also normalize path (../ will be resolved)
macro(acme_make_absolute_source_filename _var)
	if(NOT IS_ABSOLUTE "${${_var}}")
		set(${_var} "${CMAKE_CURRENT_SOURCE_DIR}/${${_var}}")
	endif()
	get_filename_component(${_var} "${${_var}}" ABSOLUTE)
endmacro()

# make relative file names absolute by prefixing with CMAKE_CURRENT_SOURCE_DIR
# also normalize path (../ will be resolved)
macro(acme_get_absolute_source_filename _var _path)
	set(${_var} "${_path}")
	acme_make_absolute_source_filename(${_var})
endmacro()


# Check if ${file} needs an include guard and add if yes
# This is the core function which does not checks the
# cache variable if we've already checked this function
# It examines the file if whether it has an include guard
function(acme_add_include_guard_if_needed_core file)
	if(NOT IS_ABSOLUTE ${file})
		set(file ${CMAKE_CURRENT_SOURCE_DIR}/${file})
	endif()

	unset(v)
	if(EXISTS ${file} AND NOT IS_DIRECTORY)
		file(STRINGS ${file} v)
	endif()
	if(NOT v)
		return()
	endif()

	# get the first 2 non-empty lines
	unset(guard)
	unset(guard2)
	set(status wait_for_first_line)
	foreach(i ${v})
		string(STRIP "${i}" i)
		string(REGEX MATCH "^[ \t]*//" is_cpp_comment "${i}")
		string(REGEX MATCH "^[ \t]*/[*]" c_comment_begins "${i}")
		string(REGEX MATCH "[*]/[ \t]*(//.*)?$" c_comment_ends "${i}")
		if(NOT "${i}" STREQUAL "" AND NOT is_cpp_comment)
			if(c_comment_begins)
				set(status_before_c_comment ${status})
				set(status wait_for_c_comment_end)
			elseif(status STREQUAL wait_for_c_comment_end)
				if(c_comment_ends)
					set(status ${status_before_c_comment})
				endif()
			elseif(status STREQUAL wait_for_first_line)
				# try reading first line of include guard
				string(REGEX MATCH "^[ \t]*#ifndef[ \t]+([a-zA-Z_][a-zA-Z0-9_]*)[ \t]*$" v "${i}")
				if(NOT v)
					set(status no_guard)
					break()
				endif()
				set(guard_id ${CMAKE_MATCH_1})
				set(status wait_for_second_line)
			elseif(status STREQUAL wait_for_second_line)
				# read second line of include guard
				string(REGEX MATCH "^[ \t]*#define[ \t]+${guard_id}[ \t]*$" v "${i}")
				if(v)
					set(status has_guard)
				else()
					set(status no_guard)
				endif()
				break()
			else()
				message(FATAL_ERROR "Invalid status: ${status}")
			endif()
		endif()
	endforeach()
	if(status STREQUAL has_guard) # already has an include guard
		return()
	endif()
	# add include guard
	file(READ ${file} file_content)
	string(RANDOM rnd)
	get_filename_component(fn ${file} NAME)
	string(TOUPPER ${fn}_INCLUDED_${rnd} fn)
	string(MAKE_C_IDENTIFIER ${fn} fn)
	file(WRITE ${file}.${rnd} "#ifndef ${fn}\n#define ${fn}\n\n${file_content}\n\n#endif /* ${fn} */\n")
	file(RENAME ${file}.${rnd} ${file})
	message(STATUS "Include guard added to ${file}")
endfunction()

# check if ${file} needs an include guard and add if yes
function(acme_add_include_guard_if_needed file)
	  string(MAKE_C_IDENTIFIER ${file} cid)
	  set(varname ACME_INCLUDE_GUARD_CHECKED_${cid})
	  #if(NOT ${varname})
	  	set(${varname} 1 CACHE INTERNAL "")
	  	acme_add_include_guard_if_needed_core(${file})
	  #endif()
endfunction()
