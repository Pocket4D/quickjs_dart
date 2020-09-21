cmake_minimum_required(VERSION 3.6.0)
project(quickjs VERSION 1.0.0 LANGUAGES C CXX)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17 -DANDROID_STL=c++_static -DANDROID_TOOLCHAIN=clang -DDEBUGGER_SERVER_PORT=${DEBUGGER_SERVER_PORT}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DQUICKJS")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ../../vm)
include_directories(
    ${PROJECT_SOURCE_DIR}/../src/quickjs
)
add_library( quickjs

             # Sets the library as a shared library.
             SHARED

             # Provides a relative path to your source file(s).
             ${PROJECT_SOURCE_DIR}/../src/quickjs-ffi.cpp

             ${PROJECT_SOURCE_DIR}/../src/quickjs/cutils.c
             ${PROJECT_SOURCE_DIR}/../src/quickjs/libregexp.c
             ${PROJECT_SOURCE_DIR}/../src/quickjs/libunicode.c
             ${PROJECT_SOURCE_DIR}/../src/quickjs/quickjs.c
             ${PROJECT_SOURCE_DIR}/../src/quickjs/libbf.c
    )

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DCONFIG_VERSION=\\\"2020-07-05\\\"")

target_link_libraries(quickjs)

