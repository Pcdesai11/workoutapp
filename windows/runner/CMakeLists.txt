cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target
add_executable(${BINARY_NAME} WIN32
        "flutter_window.cpp"
        "main.cpp"
        "utils.cpp"
        "win32_window.cpp"
        "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
        "Runner.rc"
        "runner.exe.manifest"
)

# Apply the standard settings
apply_standard_settings(${BINARY_NAME})

# Add compiler define for the Flutter's build directory
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_BUILD_DIR=\"${CMAKE_CURRENT_SOURCE_DIR}/../build/\"")

# Add dependency libraries
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)

# Run the Flutter tool portions that are contained in flutter/ephemeral.
add_dependencies(${BINARY_NAME} flutter_assemble)