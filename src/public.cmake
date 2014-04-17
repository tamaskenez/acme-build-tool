# acme_initialize(<package-name> [INCLUDE_DIR_SLASH|INCLUDE_DIR_DOT])
#
# Initialize acme package for the current directory.
# <package-name> is interpeted as a dot-separated
# list of package name components (e.g. company.foo.bar)
# A single component package name 'mycomponent' is also
# a valid package name.
#
# Specify INCLUDE_DIR_SLASH(default) or INCLUDE_DIR_DOT to
# control where the public headers will be installed, e.g.:
# ${CMAKE_PREFIX_PATH}/include/company/foo/bar or
# ${CMAKE_PREFIX_PATH}/include/company.foo.bar.
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
# - defines the install location of the public headers
#   The public headers will be installed into
#   ${CMAKE_INSTALL_PREFIX}/${ACME_INCLUDE_DIR}/${ACME_PACKAGE_INCLUDE_DIR}
# - can be used as the C++ namespace for this package
#   (see acme macros like //#{, //#}, //#., //#acme namespace)
macro(acme_initialize _acme_package_name)
	
	cmake_parse_arguments(
		ACME_INITIALIZE
		"INCLUDE_DIR_DOT;INCLUDE_DIR_SLASH"
		""
		""
		${ARGN})

	if(ACME_INITIALIZE_INCLUDE_DIR_DOT AND ACME_INITIALIZE_INCLUDE_DIR_SLASH)
		message(FATAL_ERROR "Both INCLUDE_DIR_DOT and INCLUDE_DIR_SLASH are specified.")
	endif()

	set(ACME_PACKAGE_NAME ${_acme_package_name})
	string(REPLACE "." "/" ACME_PACKAGE_NAME_SLASH ${ACME_PACKAGE_NAME})

	if(ACME_INITIALIZE_INCLUDE_DIR_DOT)
		set(ACME_PACKAGE_INCLUDE_DIR ${ACME_PACKAGE_NAME})
	else()
		set(ACME_PACKAGE_INCLUDE_DIR ${ACME_PACKAGE_NAME_SLASH})
	endif()

	message(STATUS "ACME package name: ${ACME_PACKAGE_NAME}")
endmacro()

#    acme_find_package(<package-name> <other-usual-find-package-args>
#         [NAMESPACE <namespace>]
#         [ALIAS .|<namespace-alias>]
#         [PUBLIC|PRIVATE])
#
# acme_find_package is a replacement for find_package. Differences:
#
# - Calls find_package
# - If package found creates import lib for the package (first checks
#   whether the find module or config itself created an import lib)
# - Remembers the find_package args to include in generated config modules
# - Skips find_package and import lib creation if there's already
#   a target with the same name.
#
# Use the ALIAS to attach a namespace alias to the package's namespace.
# The alias will be used for the `//#{`, `//#}` and `//#.` acme macros
# <namespace-alias> can be either an identifier or a dot.
# Use the single dot ('.') to import the package's namespace into the local namespace.
#
# The C++ namespace alias declaration will be generated using
# the package name as namespace (e.g. 'company::foo::bar' if the package
# name is company.foo.bar)
# Use the NAMESPACE keyword to override this default.
# <namespace> can either dot-separated or double-colon separated
# Recommended is the dot-separated format.
#
# The package (= target) names will be also appended to the global
# variable ACME_FIND_PACKAGE_SCOPED_TARGETS.
# This variable is a list of scope specifiers (PUBLIC or PRIVATE) and
# target names: 'PUBLIC <target2> PRIVATE <target2> ...'. This variable
# can be used ad a convenience to call target_link_libraries with
# all the packages found:
#
#     target_link_libraries(<target> ${ACME_FIND_PACKAGE_SCOPED_TARGETS})
#
# The keywords PUBLIC and PRIVATE specify the  default scope
# of the packages: public or private (default)
# packages. It affects the automatically generated config module.
# The PUBLIC or PRIVATE scope specifier can be overridden in
# target_link_libraries

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

	list(GET _afp_args_filtered 0 _afp_package_name) # original case package name
	string(TOUPPER "${_afp_package_name}" _afp_package_name_upper) # upper case package name

	# check if there's already a target with the same name
	get_target_property(_afp_target_name ${_afp_package_name} NAME)

	if(NOT _afp_target_name)
		find_package(${_afp_args_filtered})
		if(${_afp_package_name}_FOUND OR ${_afp_package_name_upper}_FOUND)
			get_target_property(_afp_target_name ${_afp_package_name} NAME)
		endif()
	endif()

	if(_afp_target_name OR ${_afp_package_name}_FOUND OR ${_afp_package_name_upper}_FOUND)
		if(_AFP_PUBLIC)
			set(_afp_scope PUBLIC)
			set(_afp_scope_for_target_list PUBLIC)
		elseif(_afp_private)
			set(_afp_scope PRIVATE)
			set(_afp_scope_for_target_list PRIVATE)
		else()
			unset(_afp_scope)
			set(_afp_scope_for_target_list PRIVATE)
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
			else()
				# explicit NAMESPACE was given which overrides the default package-name-derived namespace
				acme_dictionary_set(ACME_FIND_PACKAGE_NAME_TO_NAMESPACE_MAP "${_afp_package_name}" "${_afp_namespace_dots}")
			endif()
			acme_dictionary_set(ACME_NAMESPACE_TO_ALIAS_MAP "${_afp_namespace_dots}" "${_AFP_ALIAS}")
		endif()

		# create import lib if needed
		if(NOT _afp_target_name)
			add_library(IMPORT ${_afp_package_name} UNKNOWN IMPORTED)
			get_package_prefix(_afp_prefix ${_afp_package_name})
			foreach(_afp_i ${${_afp_prefix}_INCLUDE_DIRS} ${${_afp_prefix}_INCLUDE_DIR})
				set_property(TARGET ${_afp_package_name}
					APPEND PROPERTY INTERFACE_INCLUDE_DIRECTORIES
					${_afp_i}
				)
			endforeach()
			foreach(_afp_i ${${_afp_prefix}_DEFINITIONS})
				string(FIND "${_afp_i}" "/D" _afp_idx1)
				string(FIND "${_afp_i}" "-D" _afp_idx2)
				if(_afp_idx1 EQUAL 0 OR _afp_idx2 EQUAL 0)
					string(SUBTRING "${_afp_i}" 2 -1 _afp_k)
					set_property(TARGET ${_afp_package_name}
						APPEND PROPERTY INTERFACE_COMPILE_DEFINITIONS
						${_afp_k}
					)
				else()
					set_property(TARGET ${_afp_package_name}
						APPEND PROPERTY INTERFACE_COMPILE_OPTIONS
						${_afp_i}
					)
				endif()
			endforeach()
			unset(_afp_mode)
			foreach(_afp_i ${${_afp_prefix}_LIBRARIES})
				if(NOT DEFINED _afp_mode)
					if("${_afp_i}" STREQUAL general)
						set(_afp_mode general)
					elseif("${_afp_i}" STREQUAL debug)
						set(_afp_mode debug)
					elseif("${_afp_i}" STREQUAL optimized)
						set(_afp_mode optimized)
					else()
						set_property(TARGET ${_afp_package_name}
							APPEND PROPERTY INTERFACE_LINK_LIBRARIES
							${_afp_i})
					endif()
				else()
					if(${_afp_mode} STREQUAL general)
						set_property(TARGET ${_afp_package_name}
							APPEND PROPERTY INTERFACE_LINK_LIBRARIES
							${_afp_i})
					elseif(${_afp_mode} STREQUAL debug)
						set_property(TARGET ${_afp_package_name}
							APPEND PROPERTY INTERFACE_LINK_LIBRARIES
							$<$<CONFIG:Debug>:${_afp_i}>)
					elseif(${_afp_mode} STREQUAL optimized)
						set_property(TARGET ${_afp_package_name}
							APPEND PROPERTY INTERFACE_LINK_LIBRARIES
							$<$<NOT:$<CONFIG:Debug>>:${_afp_i}>)
					else()
						message(FATAL_ERROR "Internal error, invalid _afp_mode: ${_afp_mode}")
					endif()
					unset(_afp_mode)
				endif()
			endforeach()
		endif()
		list(APPEND ACME_FIND_PACKAGE_SCOPED_TARGETS ${_afp_scope_for_target_list} ${_afp_package_name})
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
	add_executable("${_aae_name}" ${_aae_v} ${_AAE_FILES})
	acme_initialize_target("${_aae_name}")
	acme_process_sources("${_aae_name}" ${_AAE_FILES})
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
	add_executable("${_aal_name}" ${_aal_v} ${_AAL_FILES})
	acme_initialize_target("${_aal_name}")
	acme_process_sources("${_aal_name}" ${_AAL_FILES})
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

acme_target_public_headers(superlib GLOB api/*.h ADD_DIR)
acme_target_public_headers(superlib GLOB api/*.h ADD_PARENT)
acme_target_public_headers(superlib FILES a.h b.h c/d.h )
#     acme_target_public_headers(<target> FILES <file> <file> ...
#                               [ROOT <root-dir>]
#                               [ADD_DIR|ADD_PARENT])
#     acme_target_public_headers(<target> <GLOB|GLOB_RECURSE> <pattern> <pattern>
#                               [ROOT <root-dir>]
#                               [ADD_DIR|ADD_PARENT])
#     acme_target_public_headers(<target> PUBLIC
#                               ROOT <root-dir>
#                               [ADD_DIR|ADD_PARENT])
#
# Specifies public headers to install. Optionally adds an include directory.
#
# You can can specify a list of files (first signature), globbing patterns (second signature) or
# refer to the header files marked with '//#acme public' (or '/*acme public*/')
#
# The files will be installed by copying the source directory hierarchy from <root-dir> to
# the package include dir (${CMAKE_INSTALL_PREFIX}/include/<package-dir>, where package-dir
# can be company/foo/bar or company.foo.bar, see acme_initialize).
# All files specified must be under the <root-dir> (immediately or indirectly).
#
# Files, globbing expression and <root-dir> with relative paths will be interpreted relative to the
# current source dir (and not ROOT)
#
# If you can omit ROOT it will default to the parent dir of the specified files.
# You can omit ROOT with the GLOB|GLOB_RECURSE signature only if there's only one
# globbing expression or all have the same parent dir.
#
# The function can also add an private include directory. ADD_DIR adds <root-dir>, ADD_PARENT
# adds parent of <root-dir>.
#
# Examples:
#
# The current source dir will be the ROOT.
#     acme_target_include_files(mylib FILES h1.h a/h2.h ADD_DIR)
#
# Access the header from within the project with #include "h.h"
#     acme_target_include_files(mylib FILES a/h.h ADD_DIR)
#
# Access the header from within the project with #include "mylib/h.h"
#     acme_target_include_files(mylib FILES a/mylib/h.h ADD_PARENT)
#
# Wrong, because ${CMAKE_CURRENT_SOURCE_DIR}/h3.h is not ${CMAKE_CURRENT_SOURCE_DIR}/a:
#     acme_target_include_files(mylib FILES h3.h ROOT a)
#
# Wrong, because globbing expressions have different parent dirs:
#     acme_target_include_files(mylib GLOB a/*.h b/.*h)
#
function(acme_add_public_headers target_name)
	set(argless_modes PUBLIC)
	set(multiarg_modes FILES;GLOB;GLOB_RECURSE)
	set(modes ${multiarg_modes} ${argless_modes})
	cmake_parse_arguments(
		APH
		"${argless_modes};ADD_PARENT;ADD_DIR"
		ROOT
		"${multiarg_modes}"
		${ARGN})
	unset(mode)
	foreach(i ${modes})
		if(APH_${i})
			list(APPEND mode ${i})
		endif()
	endforeach()
	list(LENGTH mode l)
	if(NOT l EQUAL 1)
		message(FATAL_ERROR "Specify exactly one of these keywords: ${modes}")
	endif()

	if(APH_ADD_PARENT AND APH_ADD_DIR)
		message(FATAL_ERROR "Both ADD_PARENT and ADD_DIR are specified.")
	endif()
	if(APH_ROOT)
		acme_make_absolute_source_filename(APH_ROOT)
	endif()
	foreach(m GLOB GLOB_RECURSE FILES)
	if(APH_${m})
		unset(l)
		foreach(i ${APH_${m}})
			acme_make_absolute_source_filename(i)
			list(APPEND l ${i})
		endforeach()
		set(APH_${m} ${l})
	endif()

	unset(implicit_roots)
	if(${mode} STREQUAL GLOB OR ${mode} STREQUAL "GLOB_RECURSE")
		file(${mode} APH_FILES ${APH_${mode}})
		acme_remove_acme_dir_files(APH_FILES)

		foreach(i ${APH_${mode}})
			get_filename_component(fc ${i} DIRECTORY)
			list(APPEND implicit_roots ${fc})
		endforeach()
		list(REMOVE_DUPLICATES implicit_roots)
		if(APH_ROOT)
			# must be all implicit roots below it
			foreach(i ${implicit_roots})
				string(FIND ${i} ${APH_ROOT} v)
				if(NOT v EQUAL 0)
					message(FATAL_ERROR "All globbing expressions must be below the specified ROOT, this is invalid: '${i}'")
				endif()
			endforeach()
		else()
			# all implicit roots must be the same
			list(LENGTH implicit_roots l)
			if(NOT l EQUAL 1)
				message(FATAL_ERROR "No ROOT specified and the globbing expressions have ambiguous roots: '${implicit_roots}'")
			endif()
			set(APH_ROOT ${implicit_roots})
		endif()
	endif()

	if(${mode} STREQUAL FILES)
		# determine ROOT
		if(NOT APH_ROOT)
			foreach(i ${APH_FILES})
				if(NOT APH_ROOT)
					get_filename_component(APH_ROOT ${i} DIRECTORY)
				else()
					# find the common prefix of APH_ROOT and ${i}
					while(1)
						string(FIND ${i} ${APH_ROOT} idx)
						if(idx EQUAL 0)
							break() # already a prefix
						endif()
						# try shorter root
						get_filename_component(APH_ROOT2 ${APH_ROOT} DIRECTORY)
						if("${APH_ROOT2}" STREQUAL "${APH_ROOT") # no change
							message(FATAL_ERROR "No common root found for FILES, specify ROOT")
						endif()
						set(APH_ROOT ${APH_ROOT2})
					endif()
				endif()
				# check if derived aph root is below source or binary dir
				string(FIND ${APH_ROOT} ${CMAKE_CURRENT_SOURCE_DIR} idx1)
				string(FIND ${APH_ROOT} ${CMAKE_CURRENT_BINARY_DIR} idx2)
				if(NOT idx1 EQUAL 0 AND NOT idx2 EQUAL 0)
					message(FATAL_ERROR "Derived ROOT is not below current source or binary dir. Specify explicit ROOT")
				endif()
			endforeach()
		endif()
		foreach(i ${APH_FILES})
			# ${i} must be within root
			string(FIND ${i} ${APH_ROOT} idx)
			if(NOT idx EQUAL 0)
				message(FATAL_ERROR "File '${i}'' is not below ROOT '${APH_ROOT}'")
			endif()
			# destination of ${i} is the relative path to APH_ROOT
			file(RELATIVE_PATH rp ${APH_ROOT} ${i})
			acme_dictionary_set(TARGET ${target_name} ACME_PUBLIC_HEADERS_TO_DESTINATION_MAP ${i} ${dest_dir})
			list(APPEND ACME_PUBLIC_HEADER_FILES ${i})
		endforeach()
	elseif(${mode} STREQUAL PUBLIC)
		if(NOT APH_ROOT)
			message("missing PUBLIC argument")
		endif()
		set_property(TARGET ${target_name}
			APPEND PROPERTY ACME_PUBLIC_HEADER_ROOTS ${APH_ROOT})
	else()
		message(FATAL_ERROR "Invalid keyword: ${mode}")
	endif()
	# add include dir
	unset(dir)
	if(APH_ADD_PARENT)
		get_filename_component(dir ${APH_ROOT} DIRECTORY)
	elseif(APH_ADD_DIR)
		set(dir ${APH_ROOT})
	endif()
	if(dir)
		target_include_directories(${target_name} BEFORE PRIVATE ${dir})
	endif()
endfunction()

#     acme_install(<target-name>)
#
# Installs
# - target
# - public headers specified with acme_target_public_headers or //#acme public
# - automatically generated config module
# - public headers will be installed by a custom command right after build
#   to make the public headers accessible to other targets before the
#   install phase
function(acme_install target_name)

	install(TARGETS ${target_name}
		RUNTIME DESTINATION ${ACME_INSTALL_TARGETS_RUNTIME_DESTINATION}
		ARCHIVE DESTINATION ${ACME_INSTALL_TARGETS_ARCHIVE_DESTINATION}
		LIBRARY DESTINATION ${ACME_INSTALL_TARGETS_LIBRARY_DESTINATION})

	acme_install_public_headers_from_target_add_public_headers(target_name)
	acme_install_public_headers_marked_public(target_name)
	acme_generate_and_install_config_module(target_name)
	acme_add_custom_command_to_early_install_public_headers(target_name)
endfunction()
