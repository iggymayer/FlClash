cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "wifi")
project(${PROJECT_NAME} LANGUAGES CXX)
cmake_policy(VERSION 3.14...3.25)

set(PLUGIN_NAME "wifi_plugin")

list(APPEND PLUGIN_SOURCES
  "wifi_plugin.cpp"
  "wifi_plugin.h"
)

add_library(${PLUGIN_NAME} SHARED
  "include/wifi/wifi_plugin_c_api.h"
  "wifi_plugin_c_api.cpp"
  ${PLUGIN_SOURCES}
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)
target_link_libraries(${PLUGIN_NAME} PRIVATE "wlanapi.lib")

set(wifi_bundled_libraries
  ""
  PARENT_SCOPE
)
