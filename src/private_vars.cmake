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

# ACME_INTERFACE_FILE_TO_DESTINATION_MAP_KEYS
# ACME_INTERFACE_FILE_TO_DESTINATION_MAP_VALUES
# ACME_INTERFACE_AUTO_FILE_TO_DESTINATION_MAP_KEYS
# ACME_INTERFACE_AUTO_FILE_TO_DESTINATION_MAP_VALUES
#     Dictionaries which maps the target's interface files
#     to their destination path (relative to include/<package-path>)
#     The first map is for files added with acme_target_interface,
#     the second map is for files added automatically (the files
#     tagged with (//#acme interface or /*#acme interface*/)
# ACME_INTERFACE_BASE_DIRS_FOR_AUTO_FILES
#     the base dirs for the files tagged with '#acme interface'
#     initialized in acme_add_executable/library
#     to CMAKE_CURRENT_SOURCE_DIR and CMAKE_CURRENT_BINARY_DIR
