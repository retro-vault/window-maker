# Command-line companions to Window Maker, grouped by what they act on.
#
#   config/   read and modify the defaults database, styles and icon sets
#   menu/     generate root menus from other systems' menu definitions
#   desktop/  clients that act on a running X session
#   scripts/  shell and Perl helpers (no compilation)

# Settings shared by every compiled tool.
add_library(wmaker_tool INTERFACE)
target_link_libraries(wmaker_tool INTERFACE wmaker_common)
target_compile_definitions(wmaker_tool INTERFACE
    ETCDIR="${WM_SYSCONFDIR}"
    DATADIR="${WM_PKGDATADIR}")

# Each subdirectory appends the programs it builds, so the install rule and the
# summary do not have to be kept in sync by hand.
set_property(GLOBAL PROPERTY WMAKER_TOOL_TARGETS "")

add_subdirectory(config)
add_subdirectory(menu)
add_subdirectory(desktop)
add_subdirectory(scripts)

get_property(_tool_targets GLOBAL PROPERTY WMAKER_TOOL_TARGETS)
install(TARGETS ${_tool_targets} RUNTIME DESTINATION ${WM_BINDIR})
