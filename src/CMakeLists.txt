
cmake_minimum_required(VERSION 2.8)

include(${CMAKE_CURRENT_SOURCE_DIR}/.acme/src/init.cmake)

acme_initialize(@ACME_PACKAGE_NAME@)

project(${ACME_PACKAGE_NAME})

# You can call acme_find_package() here
# the result variables of the find will be
# automatically added to the corresponding ACME_* variable.


# For this macro you can also specify exclude patterns after EXCLUDE:
# acme_add_include_guards(<patterns> EXCLUDE <patterns>) 
acme_add_include_guards(*.h *.hpp *.hxx)

# Create the list of files in ACME_SOURCE_AND_HEADER_FILES
acme_add_files(
	GLOB_RECURSE ${CMAKE_CURRENT_SOURCE_DIR}
)

# Add additional public headers (e.g. generated ones)
#acme_add_public_header(header DESTINATION dest)

# Process files from ACME_SOURCE_AND_HEADER_FILES
# - identify public headers
# - process #acme directives)
acme_process_sources()

# Add include dirs and definitions after acme_process_sources()
include_directories(
	${CMAKE_CURRENT_SOURCE_DIR}
	${ACME_FIND_PACKAGE_INCLUDE_DIRS}
)

add_definitions(${ACME_FIND_PACKAGE_DEFINITIONS})

# acme_add_install performs the following operations
# - adds target (add_executable or add_library)
# - sets target properties
# - sets target_link_libraries
# - installs target, public headers and config module
@ACME_ADD_TARGET_MACRO@(@ACME_LIBRARY_TYPE@)

# Uncomment this to generate and install an 'all' header which includes
# all the public headers
# acme_generate_and_install_all_header(all.h)




