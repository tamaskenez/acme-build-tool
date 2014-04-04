if(NOT ACME_SCRIPTS_INCLUDED)


## Variable names used in the CMakeLists.txt
# These are not hardcoded in the acme scripts

## Global, public ACME variables

# ACME_PACKAGE_NAME_SLASH
#     e.g. company/foo/bar
# ACME_PACKAGE_NAME
#     e.g. company.foo.bar
# ACME_PACKAGE_NAME_COMPONENTS
#     package name components as list
# ACME_TARGET_NAME
#    default = ACME_PACKAGE_NAME
# ACME_PUBLIC_HEADER_FILES
#     header files marked as public
# ACME_FIND_PACKAGE_INCLUDE_DIRS
# ACME_FIND_PACKAGE_LIBRARIES
# ACME_FIND_PACKAGE_DEFINITIONS
#     paths and defitions from successful acme_find_package calls
# ACME_DIR
#     the .acme subdirectory of the current cmake source
#     set during include() of this script

## Global, internal ACME variables

# ACME_INCLUDE_GUARD_CHECKED_${filename_to_c_identifier}
#     cache variable set when a header file was checked for include guard
#     to save continuous checking
# ACME_FIND_PACKAGE_NAMES
#     collected from the acme_find_package calls, but not the actual package names
#     but the prefix of the variables set by the find-module / config-module
#     e.g. it's Boost for find_package(Boost) but it's LIBXML2 for find_package(LibXml2)
# ACME_FIND_PACKAGE_${package_name}_SCOPE
#     package_name is an element from ACME_FIND_PACKAGE_NAMES
#     PUBLIC or PRIVATE or ""
#     according the whether the package is public, private or not defined (which will be private)
# ACME_FIND_PACKAGE_${package_name}_ARGS
#     package_name is an element from ACME_FIND_PACKAGE_NAMES
#     it's the arguments of the corresponding find_package call
# ACME_PUBLIC_HEADERS_TO_DESTINATION_MAP
#     key is a public header (abs path), value is the installation postfix (after include/package-dir)
# ACME_SOURCE_AND_HEADER_FILES
#     list of source and header files
# ACME_FIND_PACKAGE_NAMESPACE_LIST
# ACME_FIND_PACKAGE_NAMESPACE_ALIAS_LIST
#     list of dependent package namespaces and their
#     aliases as specified in acme_find_package_calls
#     The namespace list stores dot-separated names.
#     The alias stores c-identifiers or dot

# The variables are set in acme_add_executable and acme_add_library
# and used by the add_target/install/config-module functions and macros
# ACME_TARGET_TYPE
#     EXECUTABLE|SHARED|STATIC|MODULE|LIBRARY
#     The LIBRARY type defines SHARED or STATIC library
#     depending on the cmake variable BUILD_SHARED_LIBS
# ACME_IS_LIBRARY
#     true if ACME_TARGET_TYPE is a library type
# ACME_IS_EXECUTABLE
#     true if ACME_TARGET_TYPE is EXECUTABLE

	set(ACME_SCRIPTS_INCLUDED 1)

	set(ACME_DIR ${CMAKE_CURRENT_LIST_DIR}/..)
	get_filename_component(ACME_DIR ${ACME_DIR} ABSOLUTE)

	include(${ACME_DIR}/src/consts.cmake)

	function(acme_print_var_core acpv.x acpv.name)
		list(LENGTH ${acpv.x} acpv.l)
		if(acpv.l EQUAL 0)
			message(STATUS "'${acpv.name}' is empty")
		elseif(acpv.l EQUAL 1)
			message(STATUS "'${acpv.name}' = '${${acpv.x}}'")
		else()
			message(STATUS "'${acpv.name}' is a list of ${acpv.l} items:")
			math(EXPR acpv.l_minus_1 "${acpv.l} - 1")
			foreach(acpv.i RANGE ${acpv.l_minus_1})
				list(GET ${acpv.x} ${acpv.i} acpv.v)
				message(STATUS "    #${acpv.i}: '${acpv.v}'")
			endforeach()
		endif()
	endfunction()

	function(acme_print_var apv.x)
		acme_print_var_core(${apv.x} ${apv.x})
	endfunction()

	function(acme_print_envvar ape.x)
		set(ENV_${ape.x} $ENV{${ape.x}})
		acme_print_var_core(ENV_${ape.x} "ENV{${ape.x}}")
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

	macro(acme_list_set _als_list _als_idx _als_value)
		list(LENGTH ${_als_list} _als_length)
		if(_als_idx GREATER _als_length OR _als_idx EQUAL _als_length OR _als_idx LESS 0)
			message(FATAL_ERROR "Invalid index: ${_als_idx} (list length: ${_als_length}")
		endif()
		list(REMOVE_AT ${_als_list} ${_als_idx})
		list(LENGTH ${_als_list} _als_length)
		if(${_als_idx} EQUAL _als_length)
			list(APPEND ${_als_list} ${_als_value})
		else()
			list(INSERT ${_als_list} ${_als_idx} ${_als_value})
		endif()
	endmacro()

	macro(acme_dictionary_set _dictionary_name_in _key_in _value_in)
		list(FIND ${_dictionary_name_in}_KEYS "${_key_in}" _ads_idx)
		if(_ads_idx EQUAL -1)
			list(APPEND ${_dictionary_name_in}_KEYS "${_key_in}")
			list(APPEND ${_dictionary_name_in}_VALUES "${_value_in}")
		else()
			acme_list_set(${_dictionary_name_in}_VALUES _ads_idx ${_value_in})
		endif()
	endmacro()

	macro(acme_dictionary_get _dictionary_name_in _key_in _value_out)
		list(FIND ${_dictionary_name_in}_KEYS "${_key_in}" _ads_idx)
		if(_ads_idx EQUAL -1)
			set(${_value_out} NOTFOUND)
		else()
			list(GET ${_dictionary_name_in}_VALUES ${_ads_idx} ${_value_out})
		endif()
	endmacro()

	macro(acme_initialize _acme_package_name)
		set(ACME_PACKAGE_NAME ${_acme_package_name})
		string(REPLACE "." "/" ACME_PACKAGE_NAME_SLASH ${ACME_PACKAGE_NAME})

		string(REGEX MATCHALL "[^/]+" ACME_PACKAGE_NAME_COMPONENTS ${ACME_PACKAGE_NAME_SLASH})

		set(ACME_TARGET_NAME ${ACME_PACKAGE_NAME})

		message(STATUS "ACME package name: ${ACME_PACKAGE_NAME}")
	endmacro()

	# acme_get_project_relative_path_components path_in dir_out name_out [base_dir_out]
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

	macro(acme_set_target_properties)
		set_target_properties(${ACME_TARGET_NAME} PROPERTIES DEBUG_POSTFIX "${ACME_DEBUG_POSTFIX}")
	endmacro()

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

	function(acme_add_include_guard_if_needed file)
		  string(MAKE_C_IDENTIFIER ${file} cid)
		  set(varname ACME_INCLUDE_GUARD_CHECKED_${cid})
		  #if(NOT ${varname})
		  	set(${varname} 1 CACHE INTERNAL "")
		  	acme_add_include_guard_if_needed_core(${file})
		  #endif()
	endfunction()

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

	# acme_process_sources()
	#
	# Processes ACME_SOURCE_AND_HEADE_FILES. Relative paths interpreted
	# relative to the current source dir.
	#
	# The function performs the following processing steps
	# - collects the public headers (appends to ACME_PUBLIC_HEADER_FILES)
	# - processes //#{, //#}, //#. acme macros and generates #acme generated lines
	function(acme_process_sources)
		unset(package_list_to_find)
		# Create normalized, abs paths
		unset(filelist)
		foreach(i ${ACME_SOURCE_AND_HEADER_FILES})
			if(NOT IS_ABSOLUTE ${i})
				set(i ${CMAKE_CURRENT_SOURCE_DIR}/${i})
			endif()
			# normalize
			get_filename_component(i ${i} ABSOLUTE)
			if(EXISTS ${i} AND NOT IS_DIRECTORY ${i})
				list(APPEND filelist ${i})
			endif()
		endforeach()

		set(ACME_CMD_PUBLIC_HEADER "#acme public header")
		set(ACME_CMD_GENERATED_LINE_SUFFIX "//#acme generated line")
		set(ACME_CMD_BEGIN_PACKAGE_NAMESPACE "//#{")
		set(ACME_CMD_END_PACKAGE_NAMESPACE "//#}")
		set(ACME_CMD_USE_NAMESPACE_ALIASES_REGEX "//#[.]")
		set(ACME_CMD_USE_NAMESPACE_ALIASES_LITERAL "//#.")

		acme_source_group(${filelist})

		#find public headers
		foreach(i ${filelist})
			file(STRINGS ${i} v REGEX "^[ \t]*(//${ACME_CMD_PUBLIC_HEADER})|(/[*]#${ACME_CMD_PUBLIC_HEADER}[ \t]*[*]/)[ \t]*$")
			if(v)
				list(APPEND ACME_PUBLIC_HEADER_FILES ${i})
			endif()
		endforeach()
		set(ACME_PUBLIC_HEADER_FILES ${ACME_PUBLIC_HEADER_FILES} PARENT_SCOPE)

		unset(headers_found) # headers tested and found as a package header
		unset(headers_found_to_package_names) # the corresponding package name
		unset(headers_not_found) # headers already tested but not found as a package header

		# read through all files
		foreach(current_source_file ${filelist})
			file(RELATIVE_PATH current_source_file_relpath ${CMAKE_CURRENT_SOURCE_DIR} ${current_source_file})
			file(STRINGS ${current_source_file} current_file_list_of_include_lines REGEX "^[ \t]*#include[ \t]((\"[a-zA-Z0-9_/.-]+\")|(<[a-zA-Z0-9_/.-]+>))[ \t]*((//)|(/[*]))?.*$")
			unset(current_file_comp_def_list)
			foreach(current_line ${current_file_list_of_include_lines})
				string(REGEX MATCH "#include[ \t]+((\"([a-zA-Z0-9_/.-]+)\")|(<([a-zA-Z0-9_/.-]+)>))" w ${current_line})
				set(header "${CMAKE_MATCH_3}${CMAKE_MATCH_5}") # this is the string betwen "" or <>
				# header must not use qualified package name for local headers
				string(REGEX MATCH "^${ACME_PACKAGE_NAME_SLASH}(/.*)?$" v ${header})
				if(v)
					message(FATAL_ERROR "Don't use qualified package path for including headers of the current package, in file '${current_source_file_relpath}', line '${current_line}'.")
				endif()

				# find package name for this header
				list(FIND headers_found ${header} hf_idx)
				if(hf_idx EQUAL -1)
					list(FIND headers_not_found ${header} hnf_idx)
				else()
					set(hnf_idx -1)
				endif()
				if(hf_idx EQUAL -1 AND hnf_idx EQUAL -1)
					# try to find a package added with acme_find_package
					# that matches the path this header
					string(REGEX MATCHALL "[^/]+" hc ${header}) # header components
					unset(package_name)
					foreach(c ${hc})
						# validate header path component as package name component
						string(REGEX MATCH "^${ACME_REGEX_C_IDENTIFIER}$" v ${c})
						if(NOT v)
							# probably we're already at the filename, this package was not found
							break()
						endif()
						# the package name for the path so far
						if(package_name)
							set(package_name ${package_name}.${c})
						else()
							set(package_name ${c})
						endif()
						list(FIND ACME_FIND_PACKAGE_NAMESPACE_LIST ${package_name} namespace_idx)
						if(NOT namespace_idx EQUAL -1)
							list(LENGTH headers_found hf_idx) # will be at this idx
							list(APPEND headers_found ${header})
							list(APPEND headers_found_to_package_names ${package_name})
							break() # don't try next component
						endif()
					endforeach() # for each header path component
				endif() # if header was neither not found nor found
				if(NOT hf_idx EQUAL -1)
					list(GET headers_found_to_package_names ${hf_idx} package_name)
					list(FIND ACME_FIND_PACKAGE_NAMESPACE_LIST ${package_name} namespace_idx)
					list(GET ACME_FIND_PACKAGE_NAMESPACE_ALIAS_LIST ${namespace_idx} alias)
					if(NOT package_name OR namespace_idx EQUAL -1 OR NOT alias)
						acme_print_var(package_name)
						acme_print_var(namespace_idx)
						acme_print_var(alias)
						message(FATAL_ERROR "The variables above should be all valid here but they are not")
					endif()
					string(REPLACE "." "::" header_namespace ${package_name})
					if(alias STREQUAL ".")
						set(s "using namespace ${header_namespace}")
					else()
						set(s "namespace ${alias} = ${header_namespace}")
					endif()
					list(APPEND current_file_comp_def_list "${s}")
				endif()
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
	#    See acme_process_sources()
	#    <namespace-alias> can be either an identifier or a dot.
	#    Use dot to import the package's namespace into the local namespace.
	#    
	#    The words PUBLIC and PRIVATE specify public or private (default)
	#    packages. It affects the automatically generated config module.
	#    If no PUBLIC or PRIVATE defined and the package's header
	#    is included in a public header of this project, the package
	#    will be treated as PUBLIC.
	#
	#    Additionally the following variables will be updated with the
	#    package's corresponding variables:
	#    - ACME_FIND_PACKAGE_INCLUDE_DIRS
	#    - ACME_FIND_PACKAGE_LIBRARIES
	#    - ACME_FIND_PACKAGE_DEFINITIONS
	macro(acme_find_package)
		# process args
		unset(_afp_public) # if PUBLIC was specified
		unset(_afp_private) # if PRIVATE was specified
		unset(_afp_namespace) # contains the namespace or empty
		unset(_afp_namespace_to_store) # contains namespace with dot separator
		unset(_afp_alias) # contains the alias or empty
		set(_afp_args_filtered ${ARGV}) # will contain the filtered args, without the acme specific keywords

		# handle PUBLIC
		list(FIND _afp_args_filtered PUBLIC _afp_idx)
		if(NOT _afp_idx EQUAL -1)
			set(_afp_public 1)
			list(REMOVE_ITEM _afp_args_filtered PUBLIC)
		endif()

		# handle PRIVATE
		list(FIND _afp_args_filtered PRIVATE _afp_idx)
		if(NOT _afp_idx EQUAL -1)
			set(_afp_private 1)
			list(REMOVE_ITEM _afp_args_filtered PRIVATE)
		endif()

		# handle NAMESPACE
		list(FIND _afp_args_filtered NAMESPACE _afp_idx)
		if(NOT _afp_idx EQUAL -1)
			math(EXPR _afp_idx_plus_one "${_afp_idx} + 1")
			list(LENGTH _afp_args_filtered _afp_length)
			if(_afp_idx_plus_one LESS _afp_length)
				list(GET _afp_args_filtered ${_afp_idx_plus_one} _afp_namespace)
				list(REMOVE_AT _afp_args_filtered ${_afp_idx_plus_one})
				list(REMOVE_AT _afp_args_filtered ${_afp_idx})
				# validate namespace
				string(REGEX MATCH "${ACME_REGEX_PACKAGE_NAME_DOUBLE_COLON}|${ACME_REGEX_PACKAGE_NAME_DOT}" _afp_match "${_afp_namespace}")
				if(_afp_match)
					string(REPLACE "::" "." _afp_namespace_to_store "${_afp_namespace}")
				else()
					message(FATAL_ERROR "NAMESPACE argument '${_afp_namespace}' is not a valid namespace name")
				endif()
				list(FIND _afp_args_filtered NAMESPACE _afp_idx)
				if(NOT _afp_idx EQUAL -1)
					message(FATAL_ERROR "Multiple NAMESPACE keywords found")
				endif()
			else()
				message(FATAL_ERROR "NAMESPACE found as last element")
			endif()
		endif()

		# handle ALIAS
		list(FIND _afp_args_filtered ALIAS _afp_idx)
		if(NOT _afp_idx EQUAL -1)
			math(EXPR _afp_idx_plus_one "${_afp_idx} + 1")
			list(LENGTH _afp_args_filtered _afp_length)
			if(_afp_idx_plus_one LESS _afp_length)
				list(GET _afp_args_filtered ${_afp_idx_plus_one} _afp_alias)
				list(REMOVE_AT _afp_args_filtered ${_afp_idx_plus_one})
				list(REMOVE_AT _afp_args_filtered ${_afp_idx})
				# validate alias
				string(REGEX MATCH "^(${ACME_REGEX_C_IDENTIFIER}|[.])$" _afp_match "${_afp_alias}")
				if(NOT _afp_match)
					message(FATAL_ERROR "ALIAS argument '${_afp_alias}' is not a valid namespace alias name")
				endif()
				list(FIND _afp_args_filtered ALIAS _afp_idx)
				if(NOT _afp_idx EQUAL -1)
					message(FATAL_ERROR "Multiple ALIAS keywords found")
				endif()
			else()
				message(FATAL_ERROR "ALIAS found as last element")
			endif()
		endif()

		if(_afp_public AND _afp_private)
			message(FATAL_ERROR "Both PUBLIC and PRIVATE was specified.")
		endif()

		find_package(${_afp_args_filtered})
		list(GET _afp_args_filtered 0 _afp_package_name_orig) # original case package name
		string(TOUPPER "${_afp_package_name_orig}" _afp_package_name_upper) # upper case package name
		if(${_afp_package_name_upper}_FOUND) # use upper case, if set
			set(_afp_package_name ${_afp_package_name_upper})
		else()
			set(_afp_package_name ${_afp_package_name_orig})
		endif()
		if(${_afp_package_name}_FOUND)
			if(_afp_public)
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
			if(_afp_alias)
				if(NOT _afp_namespace_to_store)
					#validate package name as namespace name
					string(REGEX MATCH "${ACME_REGEX_PACKAGE_NAME_DOT}" _afp_match "${_afp_package_name_orig}")
					if(NOT _afp_match)
						message(FATAL_ERROR "ALIAS specified but package name '${_afp_package_name_orig}' is not a valid namespace name")
					endif()
					set(_afp_namespace ${_afp_package_name_orig}) # _afp_namespace is used in messages, must set it
					set(_afp_namespace_to_store ${_afp_package_name_orig})
				endif()
				list(FIND ACME_FIND_PACKAGE_NAMESPACE_LIST "${_afp_namespace_to_store}" _afp_idx)
				if(NOT _afp_idx EQUAL -1)
					# this namespace already has an alias
					list(GET ACME_FIND_PACKAGE_NAMESPACE_ALIAS_LIST ${_afp_idx} _afp_existing_alias})
					if(NOT "${_afp_existing_alias}" STREQUAL "${_afp_alias}")
						message(FATAL_ERROR "Attempted to redefine existing namespace alias: '${_afp_namespace}' -> '${_afp_existing_alias}', new alias: '${_afp_alias}'")
					endif()
					# existing alias and new alias are the same, nothing to do
				else()
					# add new alias
					list(APPEND ACME_FIND_PACKAGE_NAMESPACE_LIST "${_afp_namespace_to_store}")
					list(APPEND ACME_FIND_PACKAGE_NAMESPACE_ALIAS_LIST "${_afp_alias}")
				endif()
			endif()

			list(APPEND ACME_FIND_PACKAGE_NAMES ${_afp_package_name})
			set(ACME_FIND_PACKAGE_${_afp_package_name}_SCOPE "${_afp_scope}")
			set(ACME_FIND_PACKAGE_${_afp_package_name}_ARGS ${_afp_args_config})
			list(APPEND ACME_FIND_PACKAGE_INCLUDE_DIRS ${${_afp_package_name}_INCLUDE_DIRS})
			list(APPEND ACME_FIND_PACKAGE_LIBRARIES ${${_afp_package_name}_LIBRARIES})
			list(APPEND ACME_FIND_PACKAGE_DEFINITIONS ${${_afp_package_name}_DEFINITIONS})
			list(REMOVE_DUPLICATES ACME_FIND_PACKAGE_INCLUDE_DIRS)
			acme_remove_duplicate_libraries(ACME_FIND_PACKAGE_LIBRARIES)
		endif() # if package found
	endmacro()

	macro(acme_install_config_module)
		unset(ACME_CONFIG_MODULE_FIND_PACKAGE_ARGS)
		unset(ACME_DEPENDENT_PACKAGES_PUBLIC)
		unset(ACME_DEPENDENT_PACKAGES_PRIVATE)
		set(_name ${ACME_PACKAGE_NAME})
		if(ACME_TARGET_TYPE STREQUAL SHARED
			OR ACME_TARGET_TYPE STREQUAL MODULE
			OR (ACME_TARGET_TYPE STREQUAL LIBRARY AND BUILD_SHARED_LIBS)
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

	macro(acme_add_target _target_type _target_name)
		if(${_target_type} STREQUAL EXECUTABLE)
			add_executable(${_target_name} ${ARGN})
		else()
			if(_target_type STREQUAL LIBRARY)
				add_library(${_target_name} ${ARGN})
			else()
				add_library(${_target_name} ${_target_type} ${ARGN})
			endif()
		endif()
		acme_set_target_properties()
	endmacro()

	# acme_add_files(
	#	<file1> <file2> ...
	#	GLOB <dir>
	#	GLOB_RECURSE <dir>)
	#
	# Relative paths interpreted relative to current source dir
	function(acme_add_files)
		unset(mode)
		foreach(i ${ARGV})
			if(i STREQUAL GLOB)
				set(mode GLOB)
			elseif( i STREQUAL GLOB_RECURSE)
				set(mode GLOB_RECURSE)
			else()
				# file or dir
				set(ai ${i})
				if(NOT IS_ABSOLUTE ${ai})
					set(ai ${CMAKE_CURRENT_SOURCE_DIR}/${ai})
				endif()

				# normalize absolute path
				get_filename_component(ai ${ai} ABSOLUTE)

				if(mode STREQUAL GLOB OR mode STREQUAL GLOB_RECURSE)
					if(NOT IS_DIRECTORY ${ai})
						message(FATAL_ERROR "Argument after ${mode} is not a directory: '${i}'")
					endif()
					foreach(p ${ACME_SOURCE_FILE_PATTERNS} ${ACME_HEADER_FILE_PATTERNS})
						file(${mode} v ${ai}/${p})
						acme_remove_acme_dir_files(v)
						list(APPEND ACME_SOURCE_AND_HEADER_FILES ${v})
					endforeach()
				else()
					list(APPEND ACME_SOURCE_AND_HEADER_FILES ${ai})
				endif()
				unset(mode)
			endif()
		endforeach()
		set(ACME_SOURCE_AND_HEADER_FILES ${ACME_SOURCE_AND_HEADER_FILES} PARENT_SCOPE)
	endfunction()

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

	# acme_add_executable
	# (no parameters)
	macro(acme_add_executable)
		set(ACME_TARGET_TYPE EXECUTABLE)
		set(ACME_IS_EXECUTABLE 1)
		set(ACME_IS_LIBRARY 0)
		acme_add_target_and_install_all()
	endmacro()

	# acme_add_library([SHARED|STATIC|MODULE])
	# Call without parameters to add a library
	# Its type will be determined by the BUILD_SHARED_LIBS cmake
	# variable (see the cmake function add_library)
	macro(acme_add_library)
		set(ACME_IS_EXECUTABLE 0)
		set(ACME_IS_LIBRARY 1)
		if("${ARGV0}" STREQUAL "")
			unset(ACME_TARGET_TYPE)
		else()
			set(ACME_LIBRARY_TYPES MODULE SHARED STATIC)
			list(FIND ACME_LIBRARY_TYPES "${ARGV0}" _idx)
			if(NOT _idx EQUAL -1)
				set(ACME_TARGET_TYPE ${ARGV0})
			else()
				message(FATAL_ERROR "Invalid library type: ${ARGV0}")
			endif()
		endif()
		acme_add_target_and_install_all()
	endmacro()

	# acme_remove_acme_dir_files <variable-of-list-of-files>
	# Removes the files which are in the $ACME_DIR subdir
	macro(acme_remove_acme_dir_files _aradf)
		unset(_aradf2)
		foreach(i ${${_aradf}})
			string(FIND "${i}" "${ACME_DIR}" _aradf_idx)
			if(NOT _aradf_idx EQUAL 0)
				list(APPEND _aradf2 ${i})
			endif()
		endforeach()
		set(${_aradf} ${_aradf2})
		unset(_aradf2)
	endmacro()


endif()

