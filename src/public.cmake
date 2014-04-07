# acme_initialize(<package-name>)
#
# Initialize acme package for the current directory.
# <package-name> is interpeted as a dot-separated
# list of package name components (e.g. company.foo.bar)
# A single component package name 'mycomponent' is also
# a valid package name.
#
# This macro:
#
# - sets the ACME_PACKAGE_NAME and ACME_PACKAGE_NAME_SLASH
#   variables, for 'example company.foo.bar' and 'company/foo/bar'
# - logs the package name with message()
#
# The recommended package name is a dot-separated list
# of package name components, (like in Java/Python/Go). The package
# name will be used for these purposes:
#
# - defines the install location of the interface files (public headers)
#   The interface files will be installed into
#   ${CMAKE_INSTALL_PREFIX}/include/${ACME_PACKAGE_NAME[_SLASH]}
# - can be used as the C++ namespace for this package
#   (see acme macros like //#{, //#}, //#., //#acme namespace)
macro(acme_initialize _acme_package_name)
	set(ACME_PACKAGE_NAME ${_acme_package_name})
	string(REPLACE "." "/" ACME_PACKAGE_NAME_SLASH ${ACME_PACKAGE_NAME})

	set(ACME_TARGET_NAME ${ACME_PACKAGE_NAME})

	message(STATUS "ACME package name: ${ACME_PACKAGE_NAME}")
endmacro()

# same signature as find_package, plus acme specific extensions:
#
#     acme_find_package(<regular-find-package-args>
#         [NAMESPACE <namespace>]
#         [ALIAS .|<namespace-alias>]
#         [PUBLIC|PRIVATE])
#
#    Use the NAMESPACE to override the package default derived namespace.
#    The derived namespace is for example company::foo::bar if the package
#    name is company.foo.bar
#    <namespace> can either dot-separated or double-colon separated
#    Recommended is the dot-separated format.
#
#    Use the ALIAS to attach a namespace alias to the package's namespace.
#    The alias will be used for the `//#{`, `//#}` and `//#.` acme macros
#    <namespace-alias> can be either an identifier or a dot.
#    Use the single dot ('.') to import the package's namespace into the local namespace.
#    
#    The keywords PUBLIC and PRIVATE specify public or private (default)
#    packages. It affects the automatically generated config module.
#    The PUBLIC or PRIVATE scope specifier can be overridden in
#    target_link_libraries

macro(acme_find_package)
	cmake_parse_arguments(
		_AFP
		"PUBLIC;PRIVATE"
		"NAMESPACE;ALIAS"
		""
		${ARGN})

	# process args
	unset(_afp_namespace_dots) # contains namespace with dot separator
	set(_afp_args_filtered ${ARGV}) # will contain the filtered args, without the acme specific keywords
	list(REMOVE_ITEM _afp_args_filtered PUBLIC PRIVATE)

	while(1)
		list(FIND _afp_args_filtered NAMESPACE _afp_idx)
		if(_afp_idx EQUAL -1)
			break()
		endif()
		list(REMOVE_AT _afp_args_filtered ${_afp_idx}) # NAMESPACE 
		list(REMOVE_AT _afp_args_filtered ${_afp_idx}) # the parameter after NAMESPACE
	endwhile()

	while(1)
		list(FIND _afp_args_filtered ALIAS _afp_idx)
		if(_afp_idx EQUAL -1)
			break()
		endif()
		list(REMOVE_AT _afp_args_filtered ${_afp_idx}) # ALIAS
		list(REMOVE_AT _afp_args_filtered ${_afp_idx}) # the parameter after ALIAS
	endwhile()

	if(_AFP_NAMESPACE)
		# validate
		string(REGEX MATCH
			"${ACME_REGEX_PACKAGE_NAME_DOUBLE_COLON}|${ACME_REGEX_PACKAGE_NAME_DOT}"
			_afp_match
			"${_AFP_NAMESPACE}"
		)

		if(_afp_match)
			string(REPLACE "::" "." _afp_namespace_dots "${_afp_namespace}")
		else()
			message(FATAL_ERROR "NAMESPACE argument '${_afp_namespace}' is not a valid namespace name")
		endif()
	endif()

	if(_AFP_ALIAS)
		# validate
		string(REGEX MATCH "^(${ACME_REGEX_C_IDENTIFIER}|[.])$" _afp_match "${_AFP_ALIAS}")
		if(NOT _afp_match)
			message(FATAL_ERROR "ALIAS argument '${_afp_alias}' is not a valid namespace alias name")
		endif()
	endif()

	if(_AFP_PUBLIC AND _AFP_PRIVATE)
		message(FATAL_ERROR "Both PUBLIC and PRIVATE was specified.")
	endif()

	find_package(${_afp_args_filtered})
	list(GET _afp_args_filtered 0 _afp_package_name) # original case package name
	string(TOUPPER "${_afp_package_name}" _afp_package_name_upper) # upper case package name

	if(${_afp_package_name}_FOUND OR ${_afp_package_name_upper}_FOUND)
		if(_AFP_PUBLIC)
			set(_afp_scope PUBLIC)
		elseif(_afp_private)
			set(_afp_scope PRIVATE)
		else()
			unset(_afp_scope)
		endif()

		# prepare the _afp_args_filtered to be
		# used in config modules: we must be able
		# to do a find_package() without fatal errors
		# and quietly so replace REQUIRED and add COMPONENTS
		# if needed
		unset(_afp_args_config)
		foreach(_afp_i ${_afp_args_filtered})
			# replace REQUIRED with COMPONENTS
			if("${_afp_i}" STREQUAL REQUIRED)
				set(_afp_i COMPONENTS)
			endif()
			# replace COMPONENTS with "" if it's already in the list
			if("${_afp_i}" STREQUAL COMPONENTS)
				list(FIND _afp_args_config COMPONENTS _afp_i2)
				if(NOT _afp_i2 EQUAL -1)
					unset(_afp_i)
				endif()
			endif()
			if(NOT "${_afp_i}" STREQUAL "")
				list(APPEND _afp_args_config ${_afp_i})
			endif()
		endforeach()

		# add new namespace alias
		if(_AFP_ALIAS)
			if(NOT _afp_namespace_dots)
				# no explicit NAMESPACE was given, try to use package name as namespace
				# validate package name as namespace name
				string(REGEX MATCH "${ACME_REGEX_PACKAGE_NAME_DOT}" _afp_match "${_afp_package_name}")
				if(NOT _afp_match)
					message(FATAL_ERROR "ALIAS specified but package name '${_afp_package_name}' is not a valid namespace name")
				endif()
				set(_afp_namespace_dots ${_afp_package_name})
			endif()
			acme_dictionary_set(ACME_FIND_PACKAGE_NAMESPACE_TO_ALIAS_MAP "${_afp_namespace_dots}" "${_AFP_ALIAS}")
		endif()

		list(APPEND ACME_FIND_PACKAGE_NAMES ${_afp_package_name})
		set(ACME_FIND_PACKAGE_${_afp_package_name}_SCOPE "${_afp_scope}")
		set(ACME_FIND_PACKAGE_${_afp_package_name}_ARGS ${_afp_args_config})
	endif() # if package found
endmacro()

# acme_add_executable(<name> [WIN32] [MACOSX_BUNDLE] [EXCLUDE_FROM_ALL]
#	[[FILES] <file> [<file> ...]]
#	[GLOB|GLOB_RECURSE <pattern> [<pattern> ...])
# the FILES, GLOB and GLOB_RECURSE keywords can be used multiple times
macro(acme_add_executable _aae_name)
	set(_aae_options WIN32 MACOSX_BUNDLE EXCLUDE_FROM_ALL)
	cmake_parse_arguments(_AAE
		"${_aae_options}"
		""
		""
		${ARGN})
	acme_process_add_target_unprocessed_args(_AAE_FILES _AAE_GLOB _AAE_GLOB_RECURSE ${_AAE_UNPARSED_ARGUMENTS})
	acme_append_files_with_globbers(_AAE_FILES _AAE_GLOB _AAE_GLOB_RECURSE)
	# reconstruct args
	unset(_aae_v)
	foreach(_aae_i ${_aae_options})
		if(_AAE_${_aae_i})
			list(APPEND _aae_v ${_aae_i})
		endif()
	endforeach()
	add_executable(${_aae_name} ${_aae_v} ${_AAE_FILES})
	acme_initialize_target(${_aae_name})
endmacro()

# acme_add_library(<target-name> [STATIC|SHARED|MODULE] [EXCLUDE_FROM_ALL]
#	[[FILES] <file> [<file> ...]]
#	[GLOB|GLOB_RECURSE <pattern> [<pattern> ...])
# the FILES, GLOB and GLOB_RECURSE keywords can be used multiple times
macro(acme_add_library _aal_name)
	set(_aal_options STATIC SHARED MODULE EXCLUDE_FROM_ALL)
	cmake_parse_arguments(_AAL
		"${_aal_options}"
		""
		""
		${ARGN})
	acme_process_add_target_unprocessed_args(_AAL_FILES _AAL_GLOB _AAL_GLOB_RECURSE ${_AAL_UNPARSED_ARGUMENTS})
	acme_append_files_with_globbers(_AAL_FILES _AAL_GLOB _AAL_GLOB_RECURSE)
	# reconstruct args
	unset(_aal_v)
	foreach(_aal_i ${_aal_options})
		if(_AAL_${_aal_i})
			list(APPEND _aal_v ${_aal_i})
		endif()
	endforeach()
	add_executable(${_aal_name} ${_aal_v} ${_AAL_FILES})
	acme_initialize_target(${_aal_name})
endmacro()

# acme_add_include_guards(<globbing-expr> <globbing-expr> ... [EXCLUDE <globbing-expr> <globbing-expr> ...])
function(acme_add_include_guards)
	set(exclude 0)
	unset(include_list)
	unset(exclude_list)
	foreach(i ${ARGV})
		if(i STREQUAL EXCLUDE)
			set(exclude 1)
		else()
			file(GLOB_RECURSE v ${i})
			acme_remove_acme_dir_files(v)
			if(NOT exclude)
				list(APPEND include_list ${v})
			else()
				list(APPEND exclude_list ${v})
			endif()
		endif()
	endforeach()
	foreach(i ${include_list})
		list(FIND exclude_list ${i} v)
		if(v EQUAL -1)
			acme_add_include_guard_if_needed(${i})
		endif()
	endforeach()
endfunction()

# acme_process_sources(<target-name> <file1> <file2> ...)
#
# Processes ACME_SOURCE_AND_HEADE_FILES. Relative paths interpreted
# relative to the current source dir.
#
# The function performs the following processing steps
#
# - collects public header files (files marked with //#acme interface or /*#acme interface*/)
#   These files update the following target properties:
#   - ACME_INTERFACE_FILE_TO_DESTINATION_MAP_KEYS/VALUES
#
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

	set(ACME_CMD_PUBLIC_HEADER "#acme interface")
	set(ACME_CMD_GENERATED_LINE_SUFFIX "//#acme generated line")
	set(ACME_CMD_BEGIN_PACKAGE_NAMESPACE "//#{")
	set(ACME_CMD_END_PACKAGE_NAMESPACE "//#}")
	set(ACME_CMD_USE_NAMESPACE_ALIASES_REGEX "//#[.]")
	set(ACME_CMD_USE_NAMESPACE_ALIASES_LITERAL "//#.")

	acme_source_group(${filelist})

	#find interface files (public headers)
	unset(interface_files)
	unset(interface_file_destinations)
	foreach(i ${filelist})
		file(STRINGS ${i} v REGEX "^[ \t]*(//${ACME_CMD_PUBLIC_HEADER})|(/[*]#${ACME_CMD_PUBLIC_HEADER}[ \t]*[*]/)[ \t]*$")
		if(v)
			list(APPEND interface_files ${i})
			list(APPEND interface_file_destinations "")
		endif()
	endforeach()
	set_property(TARGET ${target_name} PROPERTY APPEND
		ACME_INTERFACE_AUTO_FILE_TO_DESTINATION_MAP_KEYS "${interface_files}")
	set_property(TARGET ${target_name} PROPERTY APPEND
		ACME_INTERFACE_AUTO_FILE_TO_DESTINATION_MAP_VALUES "${interface_file_destinations}")

	unset(headers_found) # headers tested and found as a package header
	unset(headers_found_to_package_names) # the corresponding package name
	unset(headers_not_found) # headers already tested but not found as a package header

	# read through all files
	foreach(current_source_file ${filelist})
		file(RELATIVE_PATH current_source_file_relpath ${CMAKE_CURRENT_SOURCE_DIR} ${current_source_file})
		file(STRINGS ${current_source_file} current_file_list_of_include_lines REGEX "^[ \t]*#include[ \t]((\"[a-zA-Z0-9_/.-]+\")|(<[a-zA-Z0-9_/.-]+>))[ \t]*((//)|(/[*]))?.*$")
		unset(current_file_comp_def_list)
#		foreach(current_line ${current_file_list_of_include_lines})
#			string(REGEX MATCH "#include[ \t]+((\"([a-zA-Z0-9_/.-]+)\")|(<([a-zA-Z0-9_/.-]+)>))" w ${current_line})
#			set(header "${CMAKE_MATCH_3}${CMAKE_MATCH_5}") # this is the string betwen "" or <>
#			# todo: here we should do something if the include mode of a header
#			# include "company/foo/bar/h.h"
#			# include "company.foo.bar/h.h"
#			# include "h.h"
#			# but first let's find the package (which can be an adjacent target)
#			# then decide if the include path is good or what to do with it
#
#			# find package name for this header
#			list(FIND headers_found ${header} hf_idx)
#			if(hf_idx EQUAL -1)
#				list(FIND headers_not_found ${header} hnf_idx)
#			else()
#				set(hnf_idx -1)
#			endif()
#			if(hf_idx EQUAL -1 AND hnf_idx EQUAL -1)
#				# try to find a package added with acme_find_package
#				# that matches the path this header
#				string(REGEX MATCHALL "[^/]+" hc ${header}) # header components
#				unset(package_name)
#				foreach(c ${hc})
#					# validate header path component as package name component
#					string(REGEX MATCH "^${ACME_REGEX_C_IDENTIFIER}$" v ${c})
#					if(NOT v)
#						# probably we're already at the filename, this package was not found
#						break()
#					endif()
#					# the package name for the path so far
#					if(package_name)
#						set(package_name ${package_name}.${c})
#					else()
#						set(package_name ${c})
#					endif()
#					list(FIND ACME_FIND_PACKAGE_NAMESPACE_LIST ${package_name} namespace_idx)
#					if(NOT namespace_idx EQUAL -1)
#						list(LENGTH headers_found hf_idx) # will be at this idx
#						list(APPEND headers_found ${header})
#						list(APPEND headers_found_to_package_names ${package_name})
#						break() # don't try next component
#					endif()
#				endforeach() # for each header path component
#			endif() # if header was neither not found nor found
#			if(NOT hf_idx EQUAL -1)
#				list(GET headers_found_to_package_names ${hf_idx} package_name)
#				list(FIND ACME_FIND_PACKAGE_NAMESPACE_LIST ${package_name} namespace_idx)
#				list(GET ACME_FIND_PACKAGE_NAMESPACE_ALIAS_LIST ${namespace_idx} alias)
#				if(NOT package_name OR namespace_idx EQUAL -1 OR NOT alias)
#					acme_print_var(package_name)
#					acme_print_var(namespace_idx)
#					acme_print_var(alias)
#					message(FATAL_ERROR "The variables above should be all valid here but they are not")
#				endif()
#				string(REPLACE "." "::" header_namespace ${package_name})
#				if(alias STREQUAL ".")
#					set(s "using namespace ${header_namespace}")
#				else()
#					set(s "namespace ${alias} = ${header_namespace}")
#				endif()
#				list(APPEND current_file_comp_def_list "${s}")
#			endif()
#		endforeach() # for each header in this file

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
