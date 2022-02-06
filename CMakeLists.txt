# see https://cliutils.gitlab.io/modern-cmake/ if you want to learn cmake
cmake_minimum_required(VERSION 3.16...3.22)

set(CMAKE_DISABLE_SOURCE_CHANGES ON)
set(CMAKE_DISABLE_IN_SOURCE_BUILD ON)

project(tfs LANGUAGES CXX)

add_subdirectory(src)
add_executable(tfs ${tfs_SRC})

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

target_compile_features(tfs PUBLIC cxx_std_17)
set_target_properties(tfs PROPERTIES CXX_STANDARD_REQUIRED ON)
set_target_properties(tfs PROPERTIES CXX_EXTENSIONS OFF)

if (NOT WIN32)
    add_compile_options(-Wall -Werror -pipe -fvisibility=hidden)
endif ()

set(CMAKE_CXX_FLAGS_PERFORMANCE "${CMAKE_CXX_FLAGS_RELEASE} -march=native")

if (CMAKE_COMPILER_IS_GNUCXX)
    add_compile_options(-fno-strict-aliasing)
endif ()

option(STATIC "Link statically" OFF)
if (STATIC)
    set(Boost_USE_STATIC_LIBS ON)
    set(Boost_USE_STATIC_RUNTIME ON)
    target_link_libraries(tfs -static)
endif()

# Find packages.
find_package(CryptoPP QUIET)
if (CryptoPP_FOUND)  # vcpkg-provided cmake package called CryptoPP
    set(Crypto++_LIBRARIES "cryptopp-static")
else()
    find_package(Crypto++ REQUIRED)
endif ()
find_package(fmt 6.1.2 REQUIRED)

# Look for vcpkg-provided libmariadb first
# If we link to the file directly, we might miss its dependencies from vcpkg
find_package(unofficial-libmariadb CONFIG QUIET)
if (unofficial-libmariadb_FOUND)
    set(MYSQL_CLIENT_LIBS "libmariadb")
else ()
    find_package(MySQL REQUIRED)
endif ()

find_package(Threads REQUIRED)
find_package(PugiXML REQUIRED)

# Selects LuaJIT if user defines or auto-detected
if (DEFINED USE_LUAJIT AND NOT USE_LUAJIT)
    set(FORCE_LUAJIT ${USE_LUAJIT})
else ()
    find_package(LuaJIT)
    set(FORCE_LUAJIT ${LuaJIT_FOUND})
endif ()
option(USE_LUAJIT "Use LuaJIT" ${FORCE_LUAJIT})

if (FORCE_LUAJIT)
    if (APPLE)
        set(CMAKE_EXE_LINKER_FLAGS "-pagezero_size 10000 -image_base 100000000")
    endif ()
else ()
    find_package(Lua REQUIRED)
endif ()

set(Boost_USE_MULTITHREADED ON)
find_package(Boost 1.71.0 REQUIRED COMPONENTS date_time system filesystem iostreams)
message(STATUS "Boost version: ${Boost_VERSION}")

include_directories(${Boost_INCLUDE_DIRS} ${Crypto++_INCLUDE_DIR} ${LUA_INCLUDE_DIR} ${MYSQL_INCLUDE_DIR} ${PUGIXML_INCLUDE_DIR})
target_link_libraries(tfs PRIVATE
        Boost::date_time
        Boost::system
        Boost::filesystem
        Boost::iostreams
        fmt::fmt
        ${CMAKE_THREAD_LIBS_INIT}
        ${Crypto++_LIBRARIES}
        ${LUA_LIBRARIES}
        ${MYSQL_CLIENT_LIBS}
        ${PUGIXML_LIBRARIES}
        )

### INTERPROCEDURAL_OPTIMIZATION ###
cmake_policy(SET CMP0069 NEW)
include(CheckIPOSupported)
check_ipo_supported(RESULT result OUTPUT error)
if (result)
    message(STATUS "IPO / LTO enabled")
    set_target_properties(tfs PROPERTIES INTERPROCEDURAL_OPTIMIZATION True)
else ()
    message(STATUS "IPO / LTO not supported: <${error}>")
endif ()
### END INTERPROCEDURAL_OPTIMIZATION ###

### Git Version ###
# Define the two required variables before including
# the source code for watching a git repository.
option(SKIP_GIT "Skip checking for git updates" OFF)
if(NOT SKIP_GIT)
	set(PRE_CONFIGURE_FILE "cmake/gitmetadata.h.in")
	set(POST_CONFIGURE_FILE "${CMAKE_CURRENT_BINARY_DIR}/gitmetadata.h")
	include(git_watcher)
	if(Git_FOUND)
		add_dependencies(tfs check_git)
		target_include_directories(tfs PRIVATE ${CMAKE_CURRENT_BINARY_DIR})
	endif()

    if(Git_FOUND AND EXISTS "${PROJECT_SOURCE_DIR}/.git")
        execute_process(COMMAND ${GIT_EXECUTABLE} submodule update --init --recursive
                WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                RESULT_VARIABLE GIT_SUBMOD_RESULT)
        if(NOT GIT_SUBMOD_RESULT EQUAL "0")
            message(FATAL_ERROR "git submodule update --init --recursive failed with ${GIT_SUBMOD_RESULT}, please checkout submodules")
        endif()
    endif()
endif()
### END  Git Version ###

# Precompiled header
target_precompile_headers(tfs PUBLIC src/otpch.h)

set(default_build_type "Release")
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    message(STATUS "Setting build type to '${default_build_type}' as none was specified.")
    set(CMAKE_BUILD_TYPE "${default_build_type}" CACHE
            STRING "Choose the type of build." FORCE)
    # Set the possible values of build type for cmake-gui
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
            "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()
