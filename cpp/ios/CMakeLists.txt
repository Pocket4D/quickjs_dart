cmake_minimum_required(VERSION 3.13 FATAL_ERROR)

# project setting
project(quickjs VERSION 1.0.0 LANGUAGES C CXX)
# file(STRINGS VERSION version)
set(quickjs_src 
    ${PROJECT_SOURCE_DIR}/../src/quickjs/quickjs.c 
    ${PROJECT_SOURCE_DIR}/../src/quickjs/libunicode.c 
    ${PROJECT_SOURCE_DIR}/../src/quickjs/libregexp.c 
    ${PROJECT_SOURCE_DIR}/../src/quickjs/cutils.c 
    # ${PROJECT_SOURCE_DIR}/../src/quickjs/quickjs-libc.c 
    ${PROJECT_SOURCE_DIR}/../src/quickjs-ffi-ios.cpp)
set(quickjs_def CONFIG_VERSION="${version}" _GNU_SOURCE)

# BigNum setting
option(QUICKJS_BIGNUM "Compile BigNum support" ON)

if(QUICKJS_BIGNUM)
   list(APPEND quickjs_src ${PROJECT_SOURCE_DIR}/../src/quickjs/libbf.c)
   list(APPEND quickjs_def CONFIG_BIGNUM)
endif()

# ios setting
set(CMAKE_CXX_STANDARD 11) # c++标准
set(CMAKE_CXX_FLAGS_DEBUG "-std=c++11 -frtti -fexceptions")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/build/output/$ENV{ABI})
set(CMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "ghostcorn@gmail.com (RR2MJFF7AJ)" CACHE INTERNAL "")

aux_source_directory(${PROJECT_SOURCE_DIR}/../src SRC_FILES)

# add_library(some STATIC ${SRC_FILES})
# compile settings
add_library(quickjs SHARED ${quickjs_src})
target_compile_definitions(quickjs PRIVATE ${quickjs_def} )

set_target_properties(quickjs PROPERTIES
    FRAMEWORK TRUE
    FRAMEWORK_VERSION A
    MACOSX_FRAMEWORK_IDENTIFIER com.pocket4d.io.quickjs_dart
# MACOSX_FRAMEWORK_INFO_PLIST Info.plist
# "current version" in semantic format in Mach-O binary file
    VERSION 1.0.0
# "compatibility version" in semantic format in Mach-O binary file
    SOVERSION 1.0.0
    PUBLIC_HEADER quickjs-ffi.h
    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "Apple Development"
    # RESOURCE "${RESOURCE_FILES}"
)



# cmake_minimum_required(VERSION 3.6.0)
# project(quickjs VERSION 1.0.0 LANGUAGES C CXX)

# # set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17 -DANDROID_STL=c++_static -DANDROID_TOOLCHAIN=clang -DDEBUGGER_SERVER_PORT=${DEBUGGER_SERVER_PORT}")
# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DQUICKJS")
# set(CMAKE_CXX_STANDARD 11) # c++标准
# set(CMAKE_CXX_FLAGS_DEBUG "-std=c++11 -frtti -fexceptions")
# set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/build/output/$ENV{ABI})
# set(CMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "ghostcorn@gmail.com (RR2MJFF7AJ)" CACHE INTERNAL "")
# set(quickjs_def CONFIG_VERSION="${version}" _GNU_SOURCE)
# # BigNum setting
# option(QUICKJS_BIGNUM "Compile BigNum support" ON)

# if(QUICKJS_BIGNUM)
#    list(APPEND quickjs_def CONFIG_BIGNUM)
# endif()

# include_directories(
#     ${PROJECT_SOURCE_DIR}/../src/quickjs
# )
# add_library( quickjs

#              # Sets the library as a shared library.
#              SHARED

#              # Provides a relative path to your source file(s).
#              ${PROJECT_SOURCE_DIR}/../src/quickjs-ffi.cpp

#              ${PROJECT_SOURCE_DIR}/../src/quickjs/cutils.c
#              ${PROJECT_SOURCE_DIR}/../src/quickjs/libregexp.c
#              ${PROJECT_SOURCE_DIR}/../src/quickjs/libunicode.c
#              ${PROJECT_SOURCE_DIR}/../src/quickjs/quickjs.c
#              ${PROJECT_SOURCE_DIR}/../src/quickjs/libbf.c
#     )

# # set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DCONFIG_VERSION=\\\"2020-07-05\\\"")

# # target_link_libraries(quickjs)
# set_target_properties(quickjs PROPERTIES
#     FRAMEWORK TRUE
#     FRAMEWORK_VERSION A
#     MACOSX_FRAMEWORK_IDENTIFIER com.pocket4d.io.quickjs_dart
# # MACOSX_FRAMEWORK_INFO_PLIST Info.plist
# # "current version" in semantic format in Mach-O binary file
#     VERSION 1.0.0
# # "compatibility version" in semantic format in Mach-O binary file
#     SOVERSION 1.0.0
#     PUBLIC_HEADER quickjs-ffi.h
#     XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "Apple Development"
#     # RESOURCE "${RESOURCE_FILES}"
# )