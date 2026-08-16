# Menu generators: build a Window Maker root menu from the applications
# installed on the system.

add_executable(wmgenmenu wmgenmenu.c)

add_executable(wmmenugen
    wmmenugen.c
    wmmenugen_misc.c
    wmmenugen_parse_wmconfig.c
    wmmenugen_parse_xdg.c)

set(_targets wmgenmenu wmmenugen)

foreach(_prog IN LISTS _targets)
    target_include_directories(${_prog} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
    target_link_libraries(${_prog} PRIVATE wmaker_tool WUtil)
endforeach()

set_property(GLOBAL APPEND PROPERTY WMAKER_TOOL_TARGETS ${_targets})
