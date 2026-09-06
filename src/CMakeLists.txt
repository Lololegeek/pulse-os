cmake_minimum_required(VERSION 3.20)
project(pulseos_native VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_library(pulseos-core STATIC
    libpulseos/process.cpp
)
target_include_directories(pulseos-core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/libpulseos/include
)
target_compile_options(pulseos-core PRIVATE
    -Wall -Wextra -Wpedantic -Wconversion -Wshadow
)

add_executable(pulse-perfd
    pulse-perfd/main.cpp
)
target_link_libraries(pulse-perfd PRIVATE pulseos-core)
target_compile_options(pulse-perfd PRIVATE
    -Wall -Wextra -Wpedantic -Wconversion -Wshadow
)

install(TARGETS pulse-perfd
    RUNTIME DESTINATION libexec/pulseos
)
