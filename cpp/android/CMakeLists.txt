# cmake_minimum_required(VERSION 3.13 FATAL_ERROR)

# # project setting
# project(quickjs VERSION 1.0.0 LANGUAGES C CXX)
# file(STRINGS VERSION version)
# set(quickjs_src 
#     ${PROJECT_SOURCE_DIR}/../src/quickjs/quickjs.c 
#     ${PROJECT_SOURCE_DIR}/../src/quickjs/libunicode.c 
#     ${PROJECT_SOURCE_DIR}/../src/quickjs/libregexp.c 
#     ${PROJECT_SOURCE_DIR}/../src/quickjs/cutils.c 
#     # ${PROJECT_SOURCE_DIR}/../src/quickjs/quickjs-libc.c 
#     ${PROJECT_SOURCE_DIR}/../src/quickjs-ffi.cpp)
# set(quickjs_def CONFIG_VERSION="${version}" _GNU_SOURCE)


# # android setting
# # set(CMAKE_SYSTEM_VERSION 16)
# # set(CMAKE_ANDROID_STL_TYPE c++_shared)  # https://blog.csdn.net/fpcc/article/details/72820934
# # set(CMAKE_BUILD_TYPE DEBUG) # 指定生成的版本。RELEASE
# # set(CMAKE_CXX_STANDARD 11) # c++标准
# # set(CMAKE_CXX_FLAGS_DEBUG "-std=c++11 -frtti -fexceptions")
# # string(APPEND CMAKE_CXX_FLAGS " -ffunction-sections -fdata-sections -fno-exceptions -fno-rtti")
# # string(APPEND CMAKE_SHARED_LINKER_FLAGS " -Wl,--gc-sections -Wl,--exclude-libs,ALL")

# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17 -DANDROID_STL=c++_static -DANDROID_TOOLCHAIN=clang -DDEBUGGER_SERVER_PORT=${DEBUGGER_SERVER_PORT}")
# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DQUICKJS")

# set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/../../android/cpp/$ENV{ABI})



# # BigNum setting(options)
# option(QUICKJS_BIGNUM "Compile BigNum support" ON)

# if(QUICKJS_BIGNUM)
#    list(APPEND quickjs_src ${PROJECT_SOURCE_DIR}/../src/quickjs/libbf.c)
#    list(APPEND quickjs_def CONFIG_BIGNUM)
# endif()


# # compile settings
# add_library(quickjs SHARED ${quickjs_src})
# target_compile_definitions(quickjs PRIVATE ${quickjs_def} )

################################


cmake_minimum_required(VERSION 3.6.0)
project(quickjs VERSION 1.0.0 LANGUAGES C CXX)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17 -DANDROID_STL=c++_static -DANDROID_TOOLCHAIN=clang -DDEBUGGER_SERVER_PORT=${DEBUGGER_SERVER_PORT}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DQUICKJS")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/../../android/cpp/$ENV{ABI})
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


