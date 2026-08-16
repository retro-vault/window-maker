# Small programs that exercise the WINGs widgets.  Handy as live references
# when writing your own WINGs application.

set(WINGS_TESTS wtest wmquery wmfile testmywidget)

add_executable(wtest wtest.c)
add_executable(wmquery wmquery.c)
add_executable(wmfile wmfile.c)
add_executable(testmywidget testmywidget.c mywidget.c)

foreach(_prog IN LISTS WINGS_TESTS)
    target_include_directories(${_prog} PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}"
        "${CMAKE_SOURCE_DIR}/src/wmaker")
    target_compile_definitions(${_prog} PRIVATE RESOURCE_PATH="${WM_WINGSDATADIR}")
    target_link_libraries(${_prog} PRIVATE
        WINGs WUtil wraster
        PkgConfig::XFT ${X11_LIBRARIES} ${WM_LIBM})
endforeach()
