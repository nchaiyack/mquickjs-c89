cmake_minimum_required(VERSION 2.8)
project(c89-patcher)

set(CMAKE_MACOSX_RPATH TRUE)
set(CMAKE_INSTALL_RPATH "\$ORIGIN;@executable_path;@loader_path")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(PSYCHEC_CXX_FLAGS)
set(PSYCHEC_CXX_FLAGS "${PSYCHEC_CXX_FLAGS} -Wall")

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_GLIBCXX_USE_CXX11_ABI=1")
add_definitions(-D_GLIBCXX_USE_CXX11_ABI=1)

set(SOURCES
    ${PROJECT_SOURCE_DIR}/Patcher.cpp
)

foreach(file ${SOURCES})
    set_source_files_properties(
        ${file} PROPERTIES
        COMPILE_FLAGS "${PSYCHEC_CXX_FLAGS}"
    )
endforeach()

include_directories(
    # Make psychec includes relative to this CMakeLists location by default.
    # Override PSYCHEC_SOURCE_DIR when configuring if needed:
    #   cmake -DPSYCHEC_SOURCE_DIR=/path/to/psychec -DPSYCHEC_BUILD_DIR=/path/to/psychec-build
    ${PSYCHEC_SOURCE_DIR}/C
)

add_library(c89-patcher SHARED ${SOURCES})

# Discover and link against psychecfe from a relative build tree.
# Defaults assume this repo layout:
#   mquickjs-c89/
#     new-patching/patcher  (this project)
#     psychec                (psychec sources)
#     new-patching/psychec-build (psychec CMake build dir)

# Paths relative to this CMakeLists.txt. Can be overridden by -D at configure time.
set(PSYCHEC_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/../../psychec" CACHE PATH "Path to psychec sources")
set(PSYCHEC_BUILD_DIR  "${CMAKE_CURRENT_LIST_DIR}/../psychec-build" CACHE PATH "Path to psychec build directory")

# Look for the compiled psychecfe library in common folders inside the build dir.
find_library(PSYCHECFE_LIBRARY
    NAMES psychecfe
    HINTS "${PSYCHEC_BUILD_DIR}" "${PSYCHEC_BUILD_DIR}/C" "${PSYCHEC_BUILD_DIR}/lib" "${PSYCHEC_BUILD_DIR}/lib64"
    PATH_SUFFIXES lib lib64
)

if(NOT PSYCHECFE_LIBRARY)
    message(FATAL_ERROR "Could not find psychecfe library. Build psychec first (e.g., make psychec) or set PSYCHEC_BUILD_DIR to the correct path.")
endif()

target_link_libraries(c89-patcher PRIVATE ${PSYCHECFE_LIBRARY})