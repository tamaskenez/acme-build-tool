cmake_minimum_required(VERSION 2.8)

include(${CMAKE_CURRENT_SOURCE_DIR}/.acme/src/init.cmake)
include(${ACME_DIR}/src/testlib.cmake)

acme_initialize(acme.test_standalone_functions)
project(${ACME_PACKAGE_NAME})

acme_get_project_relative_path_components(${CMAKE_CURRENT_SOURCE_DIR}/c1/c2 A B)
assert_strequal(A c1)
assert_strequal(B c2)

acme_get_project_relative_path_components(${CMAKE_CURRENT_BINARY_DIR}/c1/c2 A B)
assert_strequal(A c1)
assert_strequal(B c2)

acme_get_project_relative_path_components(/a/b/c1 A B)
assert_strequal(A NOTFOUND)
assert_strequal(B c1)

acme_get_project_relative_path_components(${CMAKE_CURRENT_SOURCE_DIR}/c1 A B)
assert_empty_or_undefined(A)
assert_strequal(B c1)

acme_get_project_relative_path_components(${CMAKE_CURRENT_BINARY_DIR}/c1 A B)
assert_empty_or_undefined(A)
assert_strequal(B c1)

set(list a)
acme_list_set(list 0 x)
assert_strequal(list x)

set(list a b)
acme_list_set(list 0 x)
assert_strequal(list "x;b")

set(list a b)
acme_list_set(list 1 y)
assert_strequal(list "a;y")

acme_dictionary_set(adic z 1)
assert_strequal(adic_KEYS z)
assert_strequal(adic_VALUES 1)

acme_dictionary_get(adic z a)
assert_strequal(a 1)

acme_dictionary_get(adic x a)
assert_strequal(a NOTFOUND)

acme_dictionary_set(adic x 2)
assert_strequal(adic_KEYS "z;x")
assert_strequal(adic_VALUES "1;2")

acme_dictionary_get(adic z a)
assert_strequal(a 1)

acme_dictionary_get(adic x a)
assert_strequal(a 2)

acme_dictionary_set(adic z 3)
assert_strequal(adic_KEYS "z;x")
assert_strequal(adic_VALUES "3;2")

acme_dictionary_get(adic z a)
assert_strequal(a 3)

acme_dictionary_get(adic x a)
assert_strequal(a 2)

set(s1 ${CMAKE_CURRENT_SOURCE_DIR}/a/../b)
set(s2 a/../b)
acme_get_absolute_source_filename(s3 ${s1})
acme_get_absolute_source_filename(s4 ${s2})
acme_make_absolute_source_filename(s1)
acme_make_absolute_source_filename(s2)

assert_strequal(s1 ${CMAKE_CURRENT_SOURCE_DIR}/b)
assert_strequal(s2 ${CMAKE_CURRENT_SOURCE_DIR}/b)
assert_strequal(s1 "${s3}")
assert_strequal(s2 "${s4}")

unset(dir_out)
unset(name_out)
unset(base_dir_out)
acme_get_project_relative_path_components(${CMAKE_CURRENT_SOURCE_DIR}/a/b dir_out name_out base_dir_out)
assert_strequal(dir_out a)
assert_strequal(name_out b)
assert_strequal(base_dir_out ${CMAKE_CURRENT_SOURCE_DIR})

unset(dir_out)
unset(name_out)
unset(base_dir_out)
acme_get_project_relative_path_components(${CMAKE_CURRENT_BINARY_DIR}/a/b dir_out name_out base_dir_out)
assert_strequal(dir_out a)
assert_strequal(name_out b)
assert_strequal(base_dir_out ${CMAKE_CURRENT_BINARY_DIR})

unset(dir_out)
unset(name_out)
unset(base_dir_out)
acme_get_project_relative_path_components(/c/a/b dir_out name_out base_dir_out)
assert_strequal(dir_out NOTFOUND)

set(v)
acme_remove_acme_dir_files(v)
assert_empty_or_undefined(v)

set(v0 ${CMAKE_CURRENT_SOURCE_DIR}/1)
set(v1 ${CMAKE_CURRENT_SOURCE_DIR}/.acme/2)
set(v2 ${CMAKE_CURRENT_SOURCE_DIR}/3)
set(v ${v0} ${v1} ${v2})
acme_remove_acme_dir_files(v)
assert_listequal(v ${v0} ${v2})

acme_process_add_target_unprocessed_args(f g gr f0 f1 GLOB g0 g1 GLOB_RECURSE gr0 gr1 FILES f2 GLOB g2 GLOB_RECURSE gr2)
assert_listequal(f f0 f1 f2)
assert_listequal(g g0 g1 g2)
assert_listequal(gr gr0 gr1 gr2)

set(f 1.h)
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/2.h)
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/2.hxx)
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/2.c)
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/2.d)
file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/3)
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/3/3.h)
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/3/3.hxx)
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/3/3.c)
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/3/3.d)
set(g ${CMAKE_CURRENT_BINARY_DIR}/*.h ${CMAKE_CURRENT_BINARY_DIR}/*.c)
set(gr ${CMAKE_CURRENT_BINARY_DIR}/*.hxx)
acme_append_files_with_globbers(f g gr)
list(SORT f)
set(ff
	1.h
	${CMAKE_CURRENT_BINARY_DIR}/2.h
	${CMAKE_CURRENT_BINARY_DIR}/2.hxx
	${CMAKE_CURRENT_BINARY_DIR}/2.c
	${CMAKE_CURRENT_BINARY_DIR}/3/3.hxx
)
list(SORT ff)
assert_listequal(f ${ff})

acme_create_package_name_candidates_from_header_path("a" p)
assert_empty_or_undefined(p)

acme_create_package_name_candidates_from_header_path("a.b" p)
assert_empty_or_undefined(p)

acme_create_package_name_candidates_from_header_path("a./b" p)
assert_empty_or_undefined(p)

acme_create_package_name_candidates_from_header_path("a./b" p)
assert_empty_or_undefined(p)

acme_create_package_name_candidates_from_header_path("a/b.h" p)
assert_listequal(p a)

acme_create_package_name_candidates_from_header_path("a/b/c.h" p)
assert_listequal(p a a.b)

acme_create_package_name_candidates_from_header_path("a.b/c.h" p)
assert_listequal(p a.b)

acme_create_package_name_candidates_from_header_path("a/b/c" p)
assert_listequal(p a a.b)

set(THAT_FOUND 1)
set(That_FOUND 1)
set(THAT_LIBRARIES)
set(That_LIBRARIES 1)
acme_get_package_prefix(v That)
assert_strequal(v That)

set(THAT_FOUND 1)
set(That_FOUND 1)
set(THAT_LIBRARIES 1)
set(That_LIBRARIES)
acme_get_package_prefix(v That)
assert_strequal(v THAT)

set(THAT_FOUND)
set(That_FOUND 1)
set(THAT_LIBRARIES)
set(That_LIBRARIES 1)
acme_get_package_prefix(v That)
assert_strequal(v That)

set(THAT_FOUND 1)
set(That_FOUND)
set(THAT_LIBRARIES 1)
set(That_LIBRARIES)
acme_get_package_prefix(v That)
assert_strequal(v THAT)

message(STATUS "Tests passed.")
