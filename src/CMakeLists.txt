cmake_minimum_required(VERSION 2.8.12)

include(${CMAKE_CURRENT_SOURCE_DIR}/.acme/src/init.cmake)
acme_initialize(@ACME_PACKAGE_NAME@)

project(${ACME_PACKAGE_NAME})

# You can call find_package() or acme_find_package() here
# acme_find_package works like find_package, plus
# - creates import libraries
# - lets you define namespace aliases
# - lets you define default scope (PUBLIC or PRIVATE) when
#   linking with all the packages found so far using
#   target_link_libraries(... ${ACME_FIND_PACKAGE_SCOPED_TARGETS})

# acme_add_library/executable works like add_library/executable, plus
# - allows inline globbing, sets source groups,
# - processes #acme macros, detects #acme interface files
# - sets target properties (debug postfix)
@ACME_ADD_TARGET_MACRO@(${ACME_PACKAGE_NAME} @ACME_LIBRARY_TYPE@
	GLOB_RECURSE ${ACME_SOURCE_FILE_PATTERNS} ${ACME_HEADER_FILE_PATTERNS})

# acme_target_link_libraries works like target_link_libraries, plus
# - if the item is not a target but a package from acme_find_package
#   or find_package, then calls target_link_libraries, target_include_directories,
#   target_compile_definitions and target_compile_options with
#   the appropriate values
# - accepts PACKAGES_FOUND to use all the packages found in this directory
target_link_libraries(${ACME_PACKAGE_NAME} ${ACME_FIND_PACKAGE_SCOPED_TARGETS})

# acme_target_interface adds further headers or other files (to be installed)
# and also include directories to the target
# acme_target_interface_files(${ACME_PACKAGE_NAME} ...)

# - installs target, interface and config module
acme_install(${ACME_PACKAGE_NAME})

# For this macro you can also specify exclude patterns after EXCLUDE:
# acme_add_include_guards(<patterns> EXCLUDE <patterns>) 
acme_add_include_guards(*.h *.hpp *.hxx)


