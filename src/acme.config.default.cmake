# config module goes to ${CMAKE_INSTALL_PREFIX}/${ACME_CONFIG_MODULE_DESTINATION}
set(ACME_CONFIG_MODULE_DESTINATION cmake)

# auto-update ACME installation from ACME_ROOT (env var must be set)
set(ACME_AUTO_UPDATE 1)

# applied in acme_add_target
set(ACME_DEBUG_POSTFIX _d)

# for globbing
set(ACME_SOURCE_FILE_PATTERNS *.c *.cc *.cpp *.cxx)
set(ACME_HEADER_FILE_PATTERNS *.h *.hxx *.hpp *.hh *.inl *.inc)

# the DESTINATION parameter for install(TARGETS ...)
set(ACME_INSTALL_TARGETS_RUNTIME_DESTINATION bin)
set(ACME_INSTALL_TARGETS_ARCHIVE_DESTINATION lib)
set(ACME_INSTALL_TARGETS_LIBRARY_DESTINATION lib)

