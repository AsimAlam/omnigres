cmake_minimum_required(VERSION 3.25.1)
project(omni_service)

include(CTest)
include(FindPkgConfig)
include(FindThreads)

list(PREPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/../../cmake)

enable_testing()

find_package(PostgreSQL REQUIRED)

add_postgresql_extension(
        omni_service
        COMMENT "Service management"
        SCHEMA omni_service
        RELOCATABLE false)