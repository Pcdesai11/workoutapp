# Project-level configuration.
cmake_minimum_required(VERSION 3.14)
project(workoutapp LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "workoutapp")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.14...3.25)

# Define build configuration option.
get_property(IS_MULTICONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(IS_MULTICONFIG)
    set(CMAKE_CONFIGURATION_TYPES "Debug;Profile;Release"
            CACHE STRING "" FORCE)
else()
    if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
        set(CMAKE_BUILD_TYPE "Debug" CACHE
                STRING "Flutter build mode" FORCE)
        set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
                "Debug" "Profile" "Release")
    endif()
endif()
# Define settings for the Profile build mode.
set(CMAKE_EXE_LINKER_FLAGS_PROFILE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
set(CMAKE_SHARED_LINKER_FLAGS_PROFILE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_PROFILE "${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_RELEASE}")

# Use Unicode for all projects.
add_definitions(-DUNICODE -D_UNICODE)

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
    target_compile_features(${TARGET} PUBLIC cxx_std_17)
    target_compile_options(${TARGET} PRIVATE /W4 /WX /wd"4100")
    target_compile_options(${TARGET} PRIVATE /EHsc)
    target_compile_definitions(${TARGET} PRIVATE "_HAS_EXCEPTIONS=0")
    target_compile_definitions(${TARGET} PRIVATE "$<$<CONFIG:Debug>:_DEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# Create the target before including plugins
add_executable(${BINARY_NAME} WIN32
        "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
        "runner/main.cpp"
        "runner/flutter_window.cpp"
        "runner/utils.cpp"
        "runner/win32_window.cpp"
        "runner/Runner.rc"
        "runner/runner.exe.manifest"
)
apply_standard_settings(${BINARY_NAME})
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_BUILD_DIR=\"${CMAKE_CURRENT_SOURCE_DIR}/build/\"")
add_dependencies(${BINARY_NAME} flutter_assemble)

# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)

# === Installation ===
# Support files are copied into place next to the executable, so that it can
# run in place. This is done instead of making a separate bundle (as on Linux)
# so that building and running from within Visual Studio will work.
set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")
# Make the "install" step default, as it's required to run.
set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
        COMPONENT Runtime)

# Only install ICU data file if it exists
if(EXISTS "${FLUTTER_ICU_DATA_FILE}")
    install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
            COMPONENT Runtime)
endif()

# Only install Flutter library if it exists
if(EXISTS "${FLUTTER_LIBRARY}")
    install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
            COMPONENT Runtime)
endif()

if(PLUGIN_BUNDLED_LIBRARIES)
    foreach(plugin_library ${PLUGIN_BUNDLED_LIBRARIES})
        if(EXISTS "${plugin_library}")
            install(FILES "${plugin_library}"
                    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
                    COMPONENT Runtime)
        endif()
    endforeach()
endif()


# Copy the native assets provided by the build.dart from all packages.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/windows/")
# Only install native assets directory if it exists
if(EXISTS "${NATIVE_ASSETS_DIR}")
    install(DIRECTORY "${NATIVE_ASSETS_DIR}"
            DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
            COMPONENT Runtime)
endif()

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
        DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
# Only install if it exists
if(EXISTS "${AOT_LIBRARY}")
    install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
            CONFIGURATIONS Profile;Release
            COMPONENT Runtime)
endif()