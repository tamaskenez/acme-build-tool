define_property(VARIABLE PROPERTY ACME_PACKAGE_NAME
	BRIEF_DOCS "Full package name, dot-separated, e.g. company.foo.bar"
	FULL_DOCS "Initialized in acme_initialize")

define_property(VARIABLE PROPERTY ACME_PACKAGE_NAME_SLASH
	BRIEF_DOCS "Full package name, slash-separated, e.g. company/foo/bar"
	FULL_DOCS "Initialized in acme_initialize")

define_property(VARIABLE PROPERTY ACME_PACKAGE_INCLUDE_DIR
	BRIEF_DOCS "Destination of the public headers, e.g. company/foo/bar or company.foo.bar"
	FULL_DOCS "Initialized in acme_initialize. The public headers will be installed into ${CMAKE_INSTALL_PREFIX}/${ACME_INCLUDE_DIR}/${ACME_PACKAGE_INCLUDE_DIR}")

define_property(VARIABLE PROPERTY ACME_DIR
	BRIEF_DOCS "The .acme subdirectory of the current cmake source."
	FULL_DOCS " Initialized in init.cmake. In case of multiple directories the .acme subdirectory of the first source directory encountered.")

define_property(VARIABLE PROPERTY ACME_FIND_PACKAGE_SCOPED_TARGETS
	BRIEF_DOCS "Packages found with acme_find_package, prefixed with the PUBLIC or PRIVATE scoping keywords."
	FULL_DOCS "For each package found an import library target is created.")


