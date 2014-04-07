cmake_minimum_required(VERSION 2.8.12)

include(public_util.cmake)
include(testlib.cmake)

set(l1 a b d)
assert_listequal(l1 a b)
