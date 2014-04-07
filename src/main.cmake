# main file that includes all the files needed in the CMakeLists.txt

include(CMakeParseArguments)

include(${CMAKE_CURRENT_LIST_DIR}/public_util.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/private_vars.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/public_vars.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/private.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/public.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/consts.cmake)
