cmake_minimum_required(VERSION 3.13 FATAL_ERROR)

set(build_os "ios")

if(CMAKE_SYSTEM_NAME MATCHES "Linux")
    set(build_os "linux")
endif()

if(CMAKE_SYSTEM_NAME MATCHES "Android")
    set(build_os "android")
endif()


if(build_os MATCHES "linux")
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ../build/linux)
endif()

if(build_os MATCHES "android")
    set(CMAKE_SYSTEM_VERSION 21)
    set(ANDROID_PLATFORM 21)
    set(CMAKE_ANDROID_NDK /Users/suwei/Library/Android/sdk/ndk-bundle/)
    set(CMAKE_TOOLCHAIN_FILE /Users/suwei/Library/Android/sdk/ndk-bundle/build/cmake/android.toolchain.cmake)
    set(CMAKE_ANDROID_STL_TYPE c++_shared)  # https://blog.csdn.net/fpcc/article/details/72820934
    set(CMAKE_BUILD_TYPE DEBUG) # 指定生成的版本。RELEASE
    set(CMAKE_CXX_STANDARD 11) # c++标准
    set(CMAKE_CXX_FLAGS_DEBUG "-std=c++11 -frtti -fexceptions")
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ../build/android/jniLibs/${CMAKE_ANDROID_ARCH_ABI})
    string(APPEND CMAKE_CXX_FLAGS " -ffunction-sections -fdata-sections -fno-exceptions -fno-rtti")
    string(APPEND CMAKE_SHARED_LINKER_FLAGS " -Wl,--gc-sections -Wl,--exclude-libs,ALL")
endif()

if(build_os MATCHES "ios")
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ../build/ios/dynamic)
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ../build/ios/static)
endif()



project(quickjs VERSION 1.0.0 LANGUAGES C)
file(STRINGS VERSION version)

# set(quickjs_src quickjs.c)

set(quickjs_src ${CMAKE_SOURCE_DIR}/quickjs/quickjs.c ${CMAKE_SOURCE_DIR}/quickjs/libunicode.c ${CMAKE_SOURCE_DIR}/quickjs/libregexp.c ${CMAKE_SOURCE_DIR}/quickjs/cutils.c ${CMAKE_SOURCE_DIR}/quickjs/quickjs-libc.c ${CMAKE_SOURCE_DIR}/quickjs-ffi.c)
set(quickjs_def CONFIG_VERSION="${version}" _GNU_SOURCE)

# BigNum setting
option(QUICKJS_BIGNUM "Compile BigNum support" ON)

if(QUICKJS_BIGNUM)
   list(APPEND quickjs_src ${CMAKE_SOURCE_DIR}/quickjs/libbf.c)
   list(APPEND quickjs_def CONFIG_BIGNUM)
endif()


# dispatch setting
# add_library(dispatch SHARED IMPORTED)
# set_target_properties(
#        dispatch
#        PROPERTIES IMPORTED_LOCATION
#        ${CMAKE_SOURCE_DIR}/../../../libs/${ANDROID_ABI}/libdispatch.so)

# BlocksRuntime setting
# add_library(BlocksRuntime SHARED IMPORTED)
# set_target_properties(
#        BlocksRuntime
#        PROPERTIES IMPORTED_LOCATION
#        ../blocksruntime-master/libBlocksRuntime.a)
        

if(BUILD_STATIC)
add_library(quickjs ${quickjs_src})
target_compile_options(quickjs PRIVATE -fblocks)
# target_compile_options(quickjs PRIVATE -lBlocksRuntime)
target_compile_definitions(quickjs PRIVATE ${quickjs_def} )
# add_library(quickjs-dumpleaks ${quickjs_src})
# target_compile_definitions(quickjs-dumpleaks PRIVATE ${quickjs_def} DUMP_LEAKS=1)
else()

add_library(quickjs SHARED ${quickjs_src})
target_compile_options(quickjs PRIVATE -fblocks)
# target_compile_options(quickjs PRIVATE -lBlocksRuntime)
target_compile_definitions(quickjs PRIVATE ${quickjs_def} )
# add_library(quickjs-dumpleaks SHARED ${quickjs_src})
# target_compile_definitions(quickjs-dumpleaks PRIVATE ${quickjs_def} DUMP_LEAKS=1)
endif()


# target_link_libraries( # Specifies the target library.
#        quickjs
#        # dispatch
#        BlocksRuntime
#        # Links the target library to the log library
#        # included in the NDK.
#        )


#set_target_properties(quickjs PROPERTIES
#    PUBLIC_HEADER quickjs-libc.h
#    VERSION ${PROJECT_VERSION}
#    SOVERSION 1
#    OUTPUT_NAME "quickjs"
#    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "Hex_Identity_ID_Goes_Here"
#)

# if(UNIX)
#    find_package(Threads)
#    target_link_libraries(quickjs ${CMAKE_DL_LIBS} m Threads::Threads)
#    target_link_libraries(quickjs-dumpleaks ${CMAKE_DL_LIBS} m Threads::Threads)
# endif()