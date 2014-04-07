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
	acme_set_target_properties(${_aae_name})
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
	acme_set_target_properties(${_aal_name})
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