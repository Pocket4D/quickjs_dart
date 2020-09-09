cmake_minimum_required(VERSION 3.13 FATAL_ERROR)

set(CMAKE_CXX_STANDARD 11) # c++标准
set(CMAKE_CXX_FLAGS_DEBUG "-std=c++11 -frtti -fexceptions")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ../../vm)

project(quickjs VERSION 1.0.0 LANGUAGES C CXX)
file(STRINGS VERSION version)
set(quickjs_src 
    ${PROJECT_SOURCE_DIR}/../src/quickjs/quickjs.c 
    ${PROJECT_SOURCE_DIR}/../src/quickjs/libunicode.c 
    ${PROJECT_SOURCE_DIR}/../src/quickjs/libregexp.c 
    ${PROJECT_SOURCE_DIR}/../src/quickjs/cutils.c 
    # ${PROJECT_SOURCE_DIR}/../src/quickjs/quickjs-libc.c 
    ${PROJECT_SOURCE_DIR}/../src/quickjs-ffi.cc)
set(quickjs_def CONFIG_VERSION="${version}" _GNU_SOURCE)

# BigNum setting
option(QUICKJS_BIGNUM "Compile BigNum support" ON)

if(QUICKJS_BIGNUM)
   list(APPEND quickjs_src ${CMAKE_SOURCE_DIR}/../src/quickjs/libbf.c)
   list(APPEND quickjs_def CONFIG_BIGNUM)
endif()

add_library(quickjs SHARED ${quickjs_src})
target_compile_options(quickjs PRIVATE -fblocks)
target_compile_definitions(quickjs PRIVATE ${quickjs_def} )

