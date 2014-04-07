# public utility functions and macros

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

# acme_print_var(<var-name>)
# formatted print of the value of the variable 
function(acme_print_var apv.x)
	acme_print_var_core(${apv.x} ${apv.x})
endfunction()

# acme_print_envvar(<env-var-name>)
# formatted print of the value of the environment variable 
function(acme_print_envvar ape.x)
	set(ENV_${ape.x} $ENV{${ape.x}})
	acme_print_var_core(ENV_${ape.x} "ENV{${ape.x}}")
endfunction()


# acme_dictionary_* macros
# Convenience macros to set a pair of variables that describe a dictionary
# (key-value pairs)
# The keys are stored in the <base-name>_KEYS list, the values
# in the <base-name>_VALUES list

# acme_dictionary_set(<base-var-name> <key> <value>)
# Set the value of a key. If the key already exists the
# value will be overwritten.
macro(acme_dictionary_set _dictionary_name_in _key_in _value_in)
	list(FIND ${_dictionary_name_in}_KEYS "${_key_in}" _ads_idx)
	if(_ads_idx EQUAL -1)
		list(APPEND ${_dictionary_name_in}_KEYS "${_key_in}")
		list(APPEND ${_dictionary_name_in}_VALUES "${_value_in}")
	else()
		acme_list_set(${_dictionary_name_in}_VALUES _ads_idx ${_value_in})
	endif()
endmacro()

# acme_dictionary_get(<base-var-name> <key> <value-var-name>)
# Get a value of a key. If the key is missing, returns NOTFOUND.
macro(acme_dictionary_get _dictionary_name_in _key_in _value_out)
	list(FIND ${_dictionary_name_in}_KEYS "${_key_in}" _ads_idx)
	if(_ads_idx EQUAL -1)
		set(${_value_out} NOTFOUND)
	else()
		list(GET ${_dictionary_name_in}_VALUES ${_ads_idx} ${_value_out})
	endif()
endmacro()

# acme_list_set(<list-var> idx value)
# sets the idx-th element of the list to value
macro(acme_list_set _als_list _als_idx _als_value)
	list(LENGTH ${_als_list} _als_length)
	if(_als_idx GREATER _als_length OR _als_idx EQUAL _als_length OR _als_idx LESS 0)
		message(FATAL_ERROR "Invalid index: ${_als_idx} (list length: ${_als_length})")
	endif()
	list(REMOVE_AT ${_als_list} ${_als_idx})
	list(LENGTH ${_als_list} _als_length)
	if(${_als_idx} EQUAL _als_length)
		list(APPEND ${_als_list} ${_als_value})
	else()
		list(INSERT ${_als_list} ${_als_idx} ${_als_value})
	endif()
endmacro()

