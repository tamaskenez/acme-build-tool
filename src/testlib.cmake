macro(assert_strequal _varname _string)
	if(NOT DEFINED ${_varname})
		message(FATAL_ERROR "assert_strequal failed, variable ${_varname} is undefined")
	endif()

	if(NOT "${${_varname}}" STREQUAL "${_string}")
		message(FATAL_ERROR "assert_strequal failed: '${_varname}' != \"${_string}\"")
	endif()
endmacro()

macro(assert_undefined _varname)
	if(DEFINED ${_varname})
		message(FATAL_ERROR "assert_undefined failed: '${_varname}' is defined, value: ${${_varname}}")
	endif()
endmacro()

macro(assert_empty_or_undefined _varname)
	if(DEFINED ${_varname} AND NOT "${${_varname}}" STREQUAL "")
		message(FATAL_ERROR "assert_empty_or_undefined failed: '${_varname}' is \"${${_varname}}\"")
	endif()
endmacro()

message(STATUS "Testlib included")