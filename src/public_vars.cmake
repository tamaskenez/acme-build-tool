define_property(VARIABLE PROPERTY ACME_PACKAGE_NAME
	BRIEF_DOCS "Full package name, dot-separated, e.g. company.foo.bar"
	FULL_DOCS "Initialized in acme_initialize")

define_property(VARIABLE PROPERTY ACME_PACKAGE_NAME_SLASH
	BRIEF_DOCS "Full package name, slash-separated, e.g. company/foo/bar"
	FULL_DOCS "Initialized in acme_initialize")

define_property(VARIABLE PROPERTY ACME_DIR
	BRIEF_DOCS "The .acme subdirectory of the current cmake source."
	FULL_DOCS " Initialized in init.cmake. In case of multiple directories the .acme subdirectory of the first source directory encountered.")

define_property(VARIABLE PROPERTY ACME_FIND_PACKAGE_TARGETS
	BRIEF_DOCS "List of package names loaded with acme_find_package."
	FULL_DOCS "For each package found an import library target is created.")


