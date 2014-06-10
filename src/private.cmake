# private functions and macros to be used by public_api.cmake

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
# Expects absolute paths. This function used for the result of a GLOB/GLOB_RECURSE
# and then they will be absolute paths.
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
macro(acme_make_absolute_source_filename _masf_var)
	if(NOT IS_ABSOLUTE "${${_masf_var}}")
		set(${_masf_var} "${CMAKE_CURRENT_SOURCE_DIR}/${${_masf_var}}")
	endif()
	get_filename_component(${_masf_var} "${${_masf_var}}" ABSOLUTE)
endmacro()

# make relative file names absolute by prefixing with CMAKE_CURRENT_SOURCE_DIR
# also normalize path (../ will be resolved)
macro(acme_get_absolute_source_filename _gasf_var _path)
	set(${_gasf_var} "${_path}")
	acme_make_absolute_source_filename(${_gasf_var})
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

# acme_initialize_target(<targe-name>)
# sets the target properties defined in an acme.config file for all acme targets
macro(acme_initialize_target _stp_target_name)
	set_target_properties(${_stp_target_name} PROPERTIES
		ACME_PUBLIC_HEADER_TO_DESTINATION_MAP_KEYS ""
		ACME_PUBLIC_HEADER_TO_DESTINATION_MAP_VALUES ""
		ACME_PUBLIC_HEADER_ROOTS "${CMAKE_CURRENT_SOURCE_DIR};${CMAKE_CURRENT_BINARY_DIR}"
		ACME_PUBLIC_HEADERS_FROM_SOURCES ""
		DEBUG_POSTFIX "${ACME_DEBUG_POSTFIX}")
endmacro()

# acme_source_group(<file1> <file2>)
#
# Sets source groups for the files
function(acme_source_group)
#list of source files
	foreach(i ${ARGN})
		acme_get_project_relative_path_components(${i} dir filename)
		if(dir STREQUAL NOTFOUND)
			set(d external)
		elseif("${dir}" STREQUAL "")
			set(d sources)
		else()
			string(REPLACE "/" "\\" d "sources/${dir}")
		endif()
		list(APPEND source_group_${d}_files ${i})
		set(source_group_${d}_name ${d})
		list(APPEND source_groups ${d})
	endforeach()
	foreach(d ${source_groups})
		source_group(${source_group_${d}_name} FILES ${source_group_${d}_files})
	endforeach()
endfunction()

# The header path is expected to be either like
#     a.b.c/d/e/f.h and then the package name could be a.b.c
# or
#     a/b/c/d/e/f.h and then the package name could be a, a.b, ... a.b.c.d.e
function(acme_create_package_name_candidates_from_header_path header candidates_var_out)
	set(${candidates_var_out} PARENT_SCOPE)

	# if no slash
	if(idx_slash EQUAL -1)
		return()
	endif()

	string(FIND "${header}" . idx_dot)
	string(FIND "${header}" / idx_slash)

	if(NOT idx_dot EQUAL -1 AND idx_dot LESS idx_slash)
		# only the dot package name is possible
		string(REGEX MATCH "^(${ACME_REGEX_C_IDENTIFIER}([.]${ACME_REGEX_C_IDENTIFIER})*)/.+" _ ${header})
		set(package_names ${CMAKE_MATCH_1})
		if(NOT _ OR NOT package_names)
			return()
		endif()
	else()
		# only the slash package name is possible
		unset(package_name)
		string(REGEX MATCHALL "[^/]+" hc ${header}) # header components
		# remove last component
		list(LENGTH hc l)
		if(l LESS 2)
			return() # there must be at least the path and the header file (a/b.h)
		endif()
		math(EXPR l "${l}-1")
		list(REMOVE_AT hc ${l})
		foreach(c ${hc})
			# validate header path component as package name component
			string(REGEX MATCH "^${ACME_REGEX_C_IDENTIFIER}$" v ${c})
			if(NOT v)
				break()
			endif()
			# the package name for the path so far
			if(package_name)
				set(package_name ${package_name}.${c})
			else()
				set(package_name ${c})
			endif()
			list(APPEND package_names ${package_name})
		endforeach()
	endif()
	set(${candidates_var_out} ${package_names} PARENT_SCOPE)
endfunction()

# acme_find_package_for_header <header_path> <package_name_var_out> <prefix_var_out>
# It tries to interpret the first part of the header_path
# as a reference to a package name, then tries
# to find either a package (previously found by
# find_package or acme_find_package) or another target
# with the same name.
# Returns either
# - if a target found: a dot-separated package name = target name and prefix = ""
# - if a package found: a dot-separated package name and a prefix that can be used to query XXX_INCLUDE_DIRS variables
# - empty variables in both output variables if nothing found
function(acme_find_package_for_header header package_name_var_out prefix_var_out)
	set(${package_name_var_out} PARENT_SCOPE)
	set(${prefix_var_out} PARENT_SCOPE)

	acme_create_package_name_candidates_from_header_path(${header} package_names)
	if(NOT package_names)
		return()
	endif()

	foreach(package_name ${package_names})
		# try to find a target
		get_target_property(name ${package_name} NAME)
		if(name)
			set(${package_name_var_out} ${package_name} PARENT_SCOPE)
			return()
		else()
			string(TOUPPER ${package_name} package_name_upper)
			unset(prefix)
			if(${package_name}_FOUND OR ${package_name_upper}_FOUND)
				acme_get_package_prefix(prefix ${package_name})
				set(${package_name_var_out} ${package_name} PARENT_SCOPE)
				set(${prefix_var_out} ${prefix} PARENT_SCOPE)
				return()
			endif()
		endif()
	endforeach() # for each header path component
endfunction()

# acme_process_sources(<target-name> <file1> <file2> ...)
#
# Processes the source files listed after the target name. Relative paths interpreted
# relative to the current source dir.
#
# The function performs the following processing steps
#
# - collects public header files (files marked with //#acme interface or /*#acme interface*/)
#   These files update the following target properties:
#   - ACME_INTERFACE_FILE_TO_DESTINATION_MAP_KEYS/VALUES
# - adds source files to source groups
# - processes //#{, //#}, //#. acme macros and generates #acme generated lines
function(acme_process_sources target_name)
	# Create normalized, abs paths of the files that do exist
	unset(filelist)
	foreach(i ${ARGN})
		acme_make_absolute_source_filename(i)
		if(EXISTS ${i} AND NOT IS_DIRECTORY ${i})
			list(APPEND filelist ${i})
		endif()
	endforeach()

	set(ACME_CMD_PUBLIC_HEADER "#acme public")
	set(ACME_CMD_GENERATED_LINE_SUFFIX "//#acme generated line")
	set(ACME_CMD_BEGIN_PACKAGE_NAMESPACE "//#{")
	set(ACME_CMD_END_PACKAGE_NAMESPACE "//#}")
	set(ACME_CMD_USE_NAMESPACE_ALIASES_REGEX "//#[.]")
	set(ACME_CMD_USE_NAMESPACE_ALIASES_LITERAL "//#.")

	acme_source_group(${filelist})

	# find interface files (public headers)
	unset(public_headers)
	foreach(i ${filelist})
		file(STRINGS ${i} v REGEX "^[ \t]*(//${ACME_CMD_PUBLIC_HEADER})|(/[*]#${ACME_CMD_PUBLIC_HEADER}[ \t]*[*]/)[ \t]*$")
		if(v)
			list(APPEND public_headers ${i})
		endif()
	endforeach()
	set_property(TARGET ${target_name} APPEND PROPERTY
		ACME_PUBLIC_HEADERS_FROM_SOURCES "${public_headers}")

	# read through all files
	foreach(current_source_file ${filelist})
		file(STRINGS ${current_source_file} current_file_list_of_include_lines REGEX "^[ \t]*#include[ \t]((\"[a-zA-Z0-9_/.-]+\")|(<[a-zA-Z0-9_/.-]+>))[ \t]*((//)|(/[*]))?.*$")
		unset(current_file_comp_def_list)
		foreach(current_line ${current_file_list_of_include_lines})
			string(REGEX MATCH "#include[ \t]+((\"([a-zA-Z0-9_/.-]+)\")|(<([a-zA-Z0-9_/.-]+)>))" w ${current_line})
			set(header "${CMAKE_MATCH_3}${CMAKE_MATCH_5}") # this is the string betwen "" or <>
			# todo: here we should do something if the include mode of a header
			# include "company/foo/bar/h.h"
			# include "company.foo.bar/h.h"
			# include "h.h"
			# but first let's find the package (which can be an adjacent target)
			# then decide if the include path is good or what to do with it

			# find package name for this header
			acme_find_package_for_header(${header} name prefix)
			if(name)
				acme_dictionary_get(ACME_FIND_PACKAGE_NAME_TO_NAMESPACE_MAP ${package_name} namespace_dots)
				if("${namespace_dots}" STREQUAL NOTFOUND)
					set(namespace_dots ${package_name})
				endif()
				acme_dictionary_get(ACME_NAMESPACE_TO_ALIAS_MAP "${namespace_dots}" alias)
				if(alias)
					string(REPLACE "." "::" header_namespace ${namespace_dots})
					if(alias STREQUAL ".")
						set(s "using namespace ${header_namespace}")
					else()
						set(s "namespace ${alias} = ${header_namespace}")
					endif()
					list(APPEND current_file_comp_def_list "${s}")
				endif()
				# BEGIN: check the way this package is included and where the include dirs are located
				# the following lines (up to END: ...) has no actual effect except warning messages
				string(REPLACE . / package_name_slash ${package_name})
				unset(existing_package_dirs)
				unset(package_include_dirs)
				if(prefix)
					# using a header from an installed package
					set(package_include_dirs ${${prefix}_INCLUDE_DIRS})
				else()
					# using a header from a target
					get_target_property(package_include_dirs ${package_name} INTERFACE_INCLUDE_DIRECTORIES)
				endif()
				unset(needs_package_path_dir)
				unset(needs_package_name_dir)
				foreach(pid ${package_include_dirs})
					set(slash_dir "${pid}/${package_name_slash}")
					set(dot_dir "${pid}/${package_name}")
					if(IS_DIRECTORY "${slash_dir}")
						set(needs_package_path_dir 1)
						list(APPEND existing_package_dirs "${slash_dir}")
					endif()
					if(IS_DIRECTORY "${dot_dir}")
						set(needs_package_name_dir 1)
						list(APPEND existing_package_dirs "${dot_dir}")
					endif()
				endforeach()
				if(NOT needs_package_path_dir AND NOT needs_package_name_dir)
					message("The file '${current_source_file}' includes the file '${header}'")
					if(prefix)
						message("An installed package has been found '${package_name}' which is supposed to contain this header")
					else()
						message("A previously added target has been found '${package_name}' which is supposed to contain this header")
					endif()
					message("but it did not provide an include directory where the directory '${package_name}' or '${package_name_slash}' could be found.")
				elseif(NOT "${package_name}" STREQUAL "${package_name_slash}" AND needs_package_path_dir AND needs_package_name_dir)
					message("The file '${current_source_file}' includes the file '${header}'")
					if(prefix)
						message("An installed package has been found '${package_name}' which is supposed to contain this header")
					else()
						message("A previously added target has been found '${package_name}' which is supposed to contain this header")
					endif()
					message("but it it provided an include directory where both the directory '${package_name}' and '${package_name_slash}' could be located. This is ambiguous, make sure only one of the is present.")
				else()
					# it needs only one package dir. Check if the current way of including (a.b.c/d.h or a/b/c/d.h)
					# is the same it needs.
					string(FIND ${header} ${package_name}/ pn_idx)
					string(FIND ${header} ${package_name_slash}/ pns_idx)

					if(needs_package_path_dir AND NOT pns_idx EQUAL 0)
						# there's a dir at a/b/c but the header path does not begin with a/b/c
						message("The file '${current_source_file}' includes the file '${header}'")
						if(prefix)
							message("An installed package has been found '${package_name}' which is supposed to contain this header")
						else()
							message("A previously added target has been found '${package_name}' which is supposed to contain this header")
						endif()
						message("The package directory can be accessed at ${package_name_slash} but the actual include line does not start with that prefix.")
						if(pn_idx EQUAL 0)
							# but it does begin with a.b.c
							message("However, it starts with ${package_name} so it could be rewritten automatically.")
						endif()
					endif()

					if(needs_package_name_dir AND NOT pn_idx EQUAL 0)
						# there's a dir at a.b.c but the header path does not begin with a.b.c
						message("The file '${current_source_file}' includes the file '${header}'")
						if(prefix)
							message("An installed package has been found '${package_name}' which is supposed to contain this header")
						else()
							message("A previously added target has been found '${package_name}' which is supposed to contain this header")
						endif()
						message("The package directory can be accessed at ${package_name} but the actual include line does not start with that prefix.")
						if(pns_idx EQUAL 0)
							# but it does begin with a/b/c
							message("However, it starts with ${package_name_slash} so it could be rewritten automatically.")
						endif()
					endif()
				endif()
				# END: check the way this package is included and where the include dirs are located
			endif() # if a package / target was found
		endforeach() # for each header in this file

		unset(csf)
		file(READ ${current_source_file} csf)

		if(csf)
			set(csf_orig "${csf}")
			# remove generated lines
			string(REGEX REPLACE "[^\n]*${ACME_CMD_GENERATED_LINE_SUFFIX}[^\n]*(\n|$)" "" csf "${csf}")

			# generate acme macros
			# _snippet_begin_namespace and _snippet_end_namespace
			# will be strings like "namespace foo { namespace bar {" and "}}"
			string(REPLACE "/" " { namespace " _snippet_begin_namespace ${ACME_PACKAGE_NAME_SLASH})
			set(_snippet_begin_namespace "namespace ${_snippet_begin_namespace} {")
			string(REGEX REPLACE "[^/]" "" _snippet_end_namespace ${ACME_PACKAGE_NAME_SLASH})
			string(REPLACE "/" "}" _snippet_end_namespace "${_snippet_end_namespace}")
			set(_snippet_end_namespace "}${_snippet_end_namespace}")

			unset(s)
			if(current_file_comp_def_list)
				list(REMOVE_DUPLICATES current_file_comp_def_list)
				foreach(i ${current_file_comp_def_list})
					set(s "${s}${i}; ${ACME_CMD_GENERATED_LINE_SUFFIX}\n")
				endforeach()
			endif()

			string(REGEX REPLACE "[ \t]*${ACME_CMD_BEGIN_PACKAGE_NAMESPACE}[ \t]*(\n|$)"
				"${ACME_CMD_BEGIN_PACKAGE_NAMESPACE}\n${_snippet_begin_namespace} ${ACME_CMD_GENERATED_LINE_SUFFIX}\n${s}"
				csf "${csf}")
			string(REGEX REPLACE "[ \t]*${ACME_CMD_END_PACKAGE_NAMESPACE}[ \t]*(\n|$)"
				"${ACME_CMD_END_PACKAGE_NAMESPACE}\n${_snippet_end_namespace} ${ACME_CMD_GENERATED_LINE_SUFFIX}\n"
				csf "${csf}")
			string(REGEX REPLACE "[ \t]*${ACME_CMD_USE_NAMESPACE_ALIASES_REGEX}[ \t]*(\n|$)"
				"${ACME_CMD_USE_NAMESPACE_ALIASES_LITERAL}\n${s}"
				csf "${csf}")
			if(NOT "${csf_orig}" STREQUAL "${csf}")
				file(WRITE ${current_source_file} "${csf}")
			endif()
		endif()
	endforeach() # for each source file
endfunction()

# acme_get_package_prefix(<var-out> <package-name>)
# Packages (find and config modules) may prefix their
# variables with original(mixed)-case and upper-case package names
# This macro finds out which one is the correct. Fails
# if inconsistency found.
# Uses an elaborate heuristics.
macro(acme_get_package_prefix _gpp_prefix_var_out _gpp_package_name)
	string(TOUPPER "${_gpp_package_name}" _gpp_package_name_upper)
	if("${_gpp_package_name}" STREQUAL "${_gpp_package_name_upper}")
		# original case == upper case
		set(${_gpp_prefix_var_out} ${_gpp_package_name})
	else()
		unset(_gpp_postfix_upper)
		unset(_gpp_postfix_original)
		unset(_gpp_postfix_both)
		set(${_gpp_prefix_var_out} ${_gpp_package_name}) # default
		if(NOT ${_gpp_package_name}_FOUND)
			if(NOT ${_gpp_package_name_upper}_FOUND)
				message(FATAL_ERROR "Internal error: package '${_gpp_package_name}' was not found")
			else()
				# this postfix set only for the upper case
				if(DEFINED ${_gpp_package_name}_FOUND)
					message(FATAL_ERROR "Inconsistent variables for package '${_gpp_package_name}': ${_gpp_package_name_upper}_FOUND but NOT ${_gpp_package_name}_FOUND")
				endif()
				# new default
				set(${_gpp_prefix_var_out} ${_gpp_package_name_upper})
			endif()
		else()
			if(NOT ${_gpp_package_name_upper}_FOUND)
				# this postfix set only for the original case
				if(DEFINED ${_gpp_package_name_upper}_FOUND)
					message(FATAL_ERROR "Inconsistent variables for package '${_gpp_package_name}': ${_gpp_package_name}_FOUND but NOT ${_gpp_package_name_upper}_FOUND")
				endif()
			else()
				# this postfix set for both cases
			endif()
		endif()

		foreach(_gpp_postfix
			INCLUDE_DIR INCLUDE_DIRS
			LIBRARY LIBRARIES
			LIBRARY_DIR LIBRARY_DIRS
			DEFINITIONS
		)
			if("${${_gpp_package_name}_${_gpp_postfix}}" STREQUAL "")
				if("${${_gpp_package_name_upper}_${_gpp_postfix}}" STREQUAL "")
					# this postfix has not been set, nothing to do
				else()
					# this postfix set only for the upper case
					list(APPEND _gpp_postfix_upper ${_gpp_postfix})
				endif()
			else()
				if("${${_gpp_package_name_upper}_${_gpp_postfix}}" STREQUAL "")
					# this postfix set only for the original case
					list(APPEND _gpp_postfix_original ${_gpp_postfix})
				else()
					# this postfix set for both cases
					if("${${_gpp_package_name}_${_gpp_postfix}}" STREQUAL "${${_gpp_package_name_upper}_${_gpp_postfix}}")
						list(APPEND _gpp_postfix_both ${_gpp_postfix})
					else()
						message(FATAL_ERROR "Inconsistent variables for package '${_gpp_package_name}': both '${_gpp_package_name}_${_gpp_postfix}' and '${_gpp_package_name_upper}_${_gpp_postfix}' are defined but they are different ( '${${_gpp_package_name}_${_gpp_postfix}}' and '${${_gpp_package_name_upper}_${_gpp_postfix}}')")
					endif()
				endif()
			endif()
		endforeach()
		if(_gpp_postfix_upper AND _gpp_postfix_original)
			message(FATAL_ERROR "Inconsistent variables for package '${_gpp_package_name}': for prefix '${_gpp_package_name}' these postfixes are defined: '${_gpp_postfix_original}', for prefix '${_gpp_package_name_upper}' these postfixes are defined: '${_gpp_postfix_upper}'")
		endif()
		if(_gpp_postfix_upper)
			set(${_gpp_prefix_var_out} ${_gpp_package_name_upper})
		elseif(_gpp_postfix_original)
			set(${_gpp_prefix_var_out} ${_gpp_package_name})
		endif()
	endif()
endmacro()

#     acme_get_nearest_public_header_relative_dir target_name(<target_name> <header_file> <best_reldir_var_out>)
#
# For a given header file <header_file> selects the nearest root (from target's ACME_PUBLIC_HEADER_ROOTS)
# and returns the relative path to that root
# The nearest root is which contains the header file and results in the shortest relative dir
function(acme_get_nearest_public_header_relative_dir target_name header_path best_root_out)
	get_target_property(roots ${target_name} ACME_PUBLIC_HEADER_ROOTS)
	# find the closest base dir
	unset(best_relative)
	unset(best_relative_length)
	foreach(bd ${roots})
		# check if inside
		string(FIND "${header_path}" "${bd}" idx)
		if(idx EQUAL 0)
			# inside this, store relative path if it's the best
			file(RELATIVE_PATH this_relative "${bd}" "${header_path}")
			string(LENGTH ${this_relative} this_relative_length)
			if(NOT DEFINED best_relative OR this_relative_length LESS best_relative_length)
				set(best_relative "${this_relative}")
				set(best_relative_length ${this_relative_length})
			endif()
		endif()
	endforeach()
	if(NOT DEFINED best_relative_length)
		message(FATAL_ERROR "Public header '${header_path}' is not located in any root specified with acme_target_public_headers(...PUBLIC...) or in the default roots (current source and binary dirs).")
	endif()
	set(${best_reldir_var_out} ${best_relative} PARENT_SCOPE)
endfunction()

function(acme_get_marked_public_headers_and_destinations target_name headers_out destinations_out)
	unset(hs)
	unset(ds)
	get_target_property(header_paths ${target_name} ACME_PUBLIC_HEADERS_FROM_SOURCES)

	foreach(hp ${header_paths})
		# find the root which is closest to hp
		# error if it's not below any root
		acme_get_nearest_public_header_relative_dir(${target_name} ${hp} bestreldir)
		list(APPEND hs ${hp})
		list(APPEND ds ${bestreldir})
	endforeach()
endfunction()

function(acme_generate_and_install_config_module target_name)
	unset(ACME_CONFIG_MODULE_FIND_PACKAGE_ARGS) # list of set(ACME_FIND_PACKAGE_<name>_ARGS ...) commands
	unset(ACME_DEPENDENT_PACKAGES_PUBLIC)
	unset(ACME_DEPENDENT_PACKAGES_PRIVATE)
	#unset(_runtime_library_name_Release)
	#unset(_runtime_library_)

	set(PREFIX ${target_name})

	get_target_property(target_type ${target_name} TYPE)
	if(target_type MATCHES "^(SHARED_LIBRARY|MODULE_LIBRARY)$")
		set(_shared 1)
	else()
		set(_shared 0)
	endif()
	#if(_shared)
	#	get_target_property(v ${target_name} LOCATION_Release)
	#	get_target_property(vd ${target_name} LOCATION_Debug)
	#	if(v)
	#		get_filename_component(j ${v} NAME)
	#		set(APPEND _runtime_library ${j})
	#	endif()
	#	if(vd)
	#		get_filename_component(j ${vd} NAME)
	#		set(APPEND _runtime_library_d ${j})
	#	endif()
	#endif()
	foreach(i ${ACME_FIND_PACKAGE_NAMES})
		set(s ${ACME_FIND_PACKAGE_${i}_SCOPE})
		if("${s}" STREQUAL "")
			set(s PRIVATE)
		endif()
		if(NOT s STREQUAL PRIVATE AND NOT s STREQUAL PUBLIC)
			message(FATAL_ERROR "find_package scope must be PUBLIC or PRIVATE")
		endif()
		list(APPEND ACME_DEPENDENT_PACKAGES_${s} ${i})
		set(ACME_CONFIG_MODULE_FIND_PACKAGE_ARGS "${ACME_CONFIG_MODULE_FIND_PACKAGE_ARGS}\nset(${PREFIX}_FIND_PACKAGE_${i}_ARGS ${ACME_FIND_PACKAGE_${i}_ARGS})")
	endforeach()

	# the next line makes, for example "cmake" -> "../"
	file(RELATIVE_PATH ACME_INSTALL_PREFIX_FROM_CONFIG_MODULE /tmp/${ACME_CONFIG_MODULE_DESTINATION} /tmp)

	configure_file(${ACME_DIR}/src/templateConfig.cmake ${PREFIX}Config.cmake.in @ONLY)
	install(
		FILES ${CMAKE_CURRENT_BINARY_DIR}/${PREFIX}Config.cmake.in
		DESTINATION ${ACME_CONFIG_MODULE_DESTINATION}
		RENAME ${PREFIX}Config.cmake)
endfunction()

#     acme_find_package_args_suppress_required out_var <arg1> <arg2> ...
# <arg1> ... are args of a find_package call
# This function removes the REQUIRED keyword and adds COMPONENTS if needed
function(acme_find_package_args_suppress_required out_var)
	unset(v)
	foreach(i ${ARGN})
		# replace REQUIRED with COMPONENTS
		if("${i}" STREQUAL REQUIRED)
			set(i COMPONENTS)
		endif()
		# replace COMPONENTS with "" if it's already in the list
		if("${i}" STREQUAL COMPONENTS)
			list(FIND v COMPONENTS idx)
			if(NOT idx EQUAL -1)
				unset(i)
			endif()
		endif()
		if(NOT "${i}" STREQUAL "")
			list(APPEND v ${i})
		endif()
	endforeach()
	set(${out_var} ${v} PARENT_SCOPE)
endfunction()
