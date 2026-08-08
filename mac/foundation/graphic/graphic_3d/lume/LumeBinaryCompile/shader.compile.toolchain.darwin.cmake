cmake_minimum_required(VERSION 3.6.0)

set(CMAKE_SYSTEM_VERSION 1)

list(APPEND CMAKE_FIND_ROOT_PATH "${OHOS_NDK}")
if(NOT CMAKE_FIND_ROOT_PATH_MODE_PROGRAM)
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
endif()

set(CMAKE_C_COMPILER "/usr/bin/clang")
set(CMAKE_CXX_COMPILER "/usr/bin/clang++")
set(CMAKE_C_FLAGS_INIT "-include stdint.h")
set(CMAKE_CXX_FLAGS_INIT "-include stdint.h")