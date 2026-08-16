# Command-line tools that act on a running X session.  The graphical
# programs that used to live here (wmagnify, wmiv) are applications and now
# live in src/apps/.

# wxcopy/wxpaste speak raw X selections and need nothing else.
add_executable(wxcopy  wxcopy.c)
add_executable(wxpaste wxpaste.c)
foreach(_prog wxcopy wxpaste)
    target_link_libraries(${_prog} PRIVATE wmaker_tool ${X11_LIBRARIES})
endforeach()

# wmsetbg spans monitors, so it wants the Xinerama/RandR bits too.
add_executable(wmsetbg wmsetbg.c)
target_link_libraries(wmsetbg PRIVATE
    wmaker_tool WINGs WUtil wraster ${WM_XEXT_LIBS} ${X11_LIBRARIES})

set(_targets wxcopy wxpaste wmsetbg)

foreach(_prog IN LISTS _targets)
    target_include_directories(${_prog} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
endforeach()

set_property(GLOBAL APPEND PROPERTY WMAKER_TOOL_TARGETS ${_targets})
