# WPrefs - the graphical preferences editor.  Also the biggest WINGs
# application in the tree, so a useful reference when writing your own.

add_executable(WPrefs
    main.c
    WPrefs.c
    Appearance.c
    Configurations.c
    Docks.c
    Expert.c
    Focus.c
    FontSimple.c
    HotCornerShortcuts.c
    Icons.c
    KeyboardShortcuts.c
    Menu.c
    MenuPreferences.c
    MouseSettings.c
    Paths.c
    Preferences.c
    TexturePanel.c
    WindowHandling.c
    Workspace.c
    double.c
    editmenu.c
    xmodifier.c)

target_include_directories(WPrefs PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")

target_compile_definitions(WPrefs PRIVATE
    RESOURCE_PATH="${WM_WPREFSDATADIR}"
    WMAKER_RESOURCE_PATH="${WM_PKGDATADIR}")

target_link_libraries(WPrefs PRIVATE
    WINGs WUtil wraster
    PkgConfig::FONTCONFIG ${X11_LIBRARIES} ${WM_LIBM})

# ---------------------------------------------------------------------------
# Desktop entry
# ---------------------------------------------------------------------------

wm_expand_file("${CMAKE_CURRENT_SOURCE_DIR}/WPrefs.desktop.in"
               "${CMAKE_BINARY_DIR}/generated/WPrefs.desktop"
               "#wprefs_bindir#"  "${WM_WPREFSBINDIR}"
               "#wprefs_datadir#" "${WM_WPREFSDATADIR}")

wm_stage_files(wprefs_desktop
    DESTINATION "${WM_STAGE_SHARE}/applications"
    FILES "${CMAKE_BINARY_DIR}/generated/WPrefs.desktop")

install(TARGETS WPrefs RUNTIME DESTINATION ${WM_BINDIR})
install(FILES "${CMAKE_BINARY_DIR}/generated/WPrefs.desktop"
        DESTINATION ${WM_DATAROOTDIR}/applications)
