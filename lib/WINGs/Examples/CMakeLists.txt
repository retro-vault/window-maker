# Example WINGs applications.

set(WINGS_EXAMPLES fontl puzzle colorpick)

foreach(_prog IN LISTS WINGS_EXAMPLES)
    add_executable(${_prog} ${_prog}.c)
    target_include_directories(${_prog} PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}"
        "${CMAKE_SOURCE_DIR}/src/wmaker")
    target_compile_definitions(${_prog} PRIVATE RESOURCE_PATH="${WM_WINGSDATADIR}")
    target_link_libraries(${_prog} PRIVATE
        WINGs WUtil wraster
        PkgConfig::XFT ${X11_LIBRARIES} ${WM_LIBM})
endforeach()
