# Tools that read and modify Window Maker's configuration: the defaults
# database, style/theme files and icon sets.

# fontconv.c is shared by the three tools that rewrite font specifications.
set(_font_conv fontconv.c)

add_executable(wdwrite     wdwrite.c)
add_executable(wdread      wdread.c)
add_executable(geticonset  geticonset.c)
add_executable(seticons    seticons.c)
add_executable(getstyle    getstyle.c ${_font_conv})
add_executable(convertfonts convertfonts.c ${_font_conv})
add_executable(setstyle    setstyle.c ${_font_conv})

set(_targets wdwrite wdread geticonset seticons getstyle convertfonts setstyle)

foreach(_prog IN LISTS _targets)
    target_include_directories(${_prog} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
    target_link_libraries(${_prog} PRIVATE wmaker_tool WUtil)
endforeach()

# setstyle talks to the X server to reload the style it just wrote.
target_link_libraries(setstyle PRIVATE ${X11_LIBRARIES})

set_property(GLOBAL APPEND PROPERTY WMAKER_TOOL_TARGETS ${_targets})
