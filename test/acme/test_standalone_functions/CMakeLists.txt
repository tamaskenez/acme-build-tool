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

message(STATUS "Tests passed.")