# private variables and initialization

# Cache variables:
#
# ACME_INCLUDE_GUARD_CHECKED_${filename_to_c_identifier}
#     cache variable set when a header file was checked for include guard
#     to save repeated checking

# Global variables

# ACME_FIND_PACKAGE_${package_name}_SCOPE
#     package_name is an item from ACME_FIND_PACKAGE_NAMES
#     PUBLIC or PRIVATE or not defined
#     according the whether the package scope is public, private or not defined
#     as given in the acme_find_package call

# ACME_FIND_PACKAGE_${package_name}_ARGS
#     package_name is an item from ACME_FIND_PACKAGE_NAMES
#     it's the arguments of the corresponding find_package call
#     processed to be included in the config module

# ACME_NAMESPACE_TO_ALIAS_MAP_KEYS
# ACME_NAMESPACE_TO_ALIAS_MAP_VALUES
#     list of dot-separated namespace names and corresponding aliases
#     an alias can be a c-identifier or a single dot (for using namespace)

# ACME_FIND_PACKAGE_NAME_TO_NAMESPACE_MAP_KEYS
# ACME_FIND_PACKAGE_NAME_TO_NAMESPACE_MAP_VALUES
#     map of those packages where a non-default
#     namespace was given with acme_find_package(... NAMESPACE ...)

# ACME_INIT_INCLUDE_DONE
#     init.cmake included

# Target properties

# ACME_PUBLIC_HEADER_TO_DESTINATION_MAP_KEYS
# ACME_PUBLIC_HEADER_TO_DESTINATION_MAP_VALUES
#     list of public headers and their destinations
#     as specified by acme_target_public_headers
#     headers marked by //#acme public are not listed here

# ACME_PUBLIC_HEADER_ROOTS
#     the roots specified by acme_target_public_headers(...PUBLIC)
#     initialized in acme_add_executable/library
#     with CMAKE_CURRENT_SOURCE_DIR and CMAKE_CURRENT_BINARY_DIR

# ACME_PUBLIC_HEADERS_FROM_SOURCES
#     list of public headers marked as //#acme public