if(DEFINED EXPECTED_DEBUG_POSTFIX AND NOT "${EXPECTED_DEBUG_POSTFIX}" STREQUAL "${ACME_DEBUG_POSTFIX}")
	message(FATAL_ERROR "ACME_DEBUG_POSTFIX: '${ACME_DEBUG_POSTFIX}', expected: '${EXPECTED_DEBUG_POSTFIX}'")
endif()
