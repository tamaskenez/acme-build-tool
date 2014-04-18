set(ACME_REGEX_C_IDENTIFIER "[a-zA-Z_][a-zA-Z_0-9]*")
set(ACME_REGEX_PACKAGE_NAME_SLASH "^${ACME_REGEX_C_IDENTIFIER}(/${ACME_REGEX_C_IDENTIFIER})*$")
set(ACME_REGEX_PACKAGE_NAME_DOT "^${ACME_REGEX_C_IDENTIFIER}([.]${ACME_REGEX_C_IDENTIFIER})*$")
set(ACME_REGEX_PACKAGE_NAME_DOUBLE_COLON "^${ACME_REGEX_C_IDENTIFIER}(::${ACME_REGEX_C_IDENTIFIER})*$")
set(ACME_BINARY_DIR acme_binary_dir) # dir name withing CMAKE_CURRENT_BINARY_DIR for acme-generated files