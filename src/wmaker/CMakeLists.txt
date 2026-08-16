# wmaker - the window manager.

set(WMAKER_SOURCES
    actions.c
    appicon.c
    application.c
    appmenu.c
    balloon.c
    client.c
    colormap.c
    cycling.c
    defaults.c
    dialog.c
    dock.c
    dockedapp.c
    event.c
    framewin.c
    geomview.c
    icon.c
    main.c
    menu.c
    misc.c
    monitor.c
    moveres.c
    pixmap.c
    placement.c
    properties.c
    resources.c
    rootmenu.c
    screen.c
    session.c
    shutdown.c
    switchpanel.c
    stacking.c
    startup.c
    superfluous.c
    switchmenu.c
    texture.c
    usermenu.c
    xinerama.c
    xmodifier.c
    xutil.c
    wcore.c
    wdefaults.c
    window.c
    winmenu.c
    winspector.c
    wmspec.c
    workspace.c
    wsmap.c)

if(USE_DOCK_XDND)
    list(APPEND WMAKER_SOURCES xdnd.c)
endif()
if(USE_MWM_HINTS)
    list(APPEND WMAKER_SOURCES motif.c)
endif()

# Platform-specific process inspection (used to tell whether a docked app is
# still running).
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    list(APPEND WMAKER_SOURCES osdep_linux.c)
elseif(CMAKE_SYSTEM_NAME MATCHES "BSD|DragonFly")
    list(APPEND WMAKER_SOURCES osdep_bsd.c)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    list(APPEND WMAKER_SOURCES osdep_darwin.c)
else()
    list(APPEND WMAKER_SOURCES osdep_stub.c)
endif()

add_executable(wmaker ${WMAKER_SOURCES})

target_include_directories(wmaker PRIVATE
    "${CMAKE_BINARY_DIR}/src"
    "${CMAKE_CURRENT_SOURCE_DIR}")

target_link_libraries(wmaker PRIVATE
    WINGs WUtil wraster
    ${WM_XEXT_LIBS} ${X11_LIBRARIES} ${WM_LIBM})

install(TARGETS wmaker RUNTIME DESTINATION ${WM_BINDIR})
