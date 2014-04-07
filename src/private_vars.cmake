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

# ACME_FIND_PACKAGE_NAMESPACE_TO_ALIAS_MAP_KEYS
# ACME_FIND_PACKAGE_NAMESPACE_TO_ALIAS_MAP_VALUES
#     list of dependent package namespaces and their
#     aliases as specified in acme_find_package_calls
#     The namespaces are dot-separated names.
#     The aliases are namespace aliases (c-identifiers) or single dots

# ACME_INIT_INCLUDE_DONE
#     init.cmake included

# Target properties

# ACME_INTERFACE_FILE_TO_DESTINATION_MAP_KEYS
# ACME_INTERFACE_FILE_TO_DESTINATION_MAP_VALUES
#     Dictionary which maps interface files for this target
#     to their destination (relative to include/<package-path>)
# ACME_INTERFACE_TAGGED_BASE_DIRS
#     the base dirs for the files tagged with '#acme interface'