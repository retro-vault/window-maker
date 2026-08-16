# Runtime data: menus, styles, icons, backgrounds and the global defaults.

set(_gen "${CMAKE_BINARY_DIR}/generated/WindowMaker")

# ---------------------------------------------------------------------------
# Menus that need the WPrefs path and the data directory patched in
# ---------------------------------------------------------------------------

set(GENERATED_MENUS
    appearance.menu appearance.menu.fy appearance.menu.nl
    menu menu.bg menu.fi menu.fy menu.hu menu.ko menu.nl menu.ro menu.sk menu.zh_TW
    plmenu plmenu.bg plmenu.es plmenu.fi plmenu.fy plmenu.ja plmenu.ko plmenu.nl
    plmenu.pl plmenu.ro plmenu.sk plmenu.zh_CN plmenu.zh_TW
    wmmacros)

set(_generated_menu_files "")
foreach(_menu IN LISTS GENERATED_MENUS)
    wm_expand_file("${CMAKE_CURRENT_SOURCE_DIR}/${_menu}.in" "${_gen}/${_menu}"
        "#wprefs#"    "${WM_WPREFSBINDIR}/WPrefs"
        "#wmdatadir#" "${WM_PKGDATADIR}")
    list(APPEND _generated_menu_files "${_gen}/${_menu}")
endforeach()

set(NONGENERATED_MENUS
    menu.ca menu.cz menu.da menu.de menu.el menu.es menu.fr menu.gl menu.he
    menu.hr menu.it menu.ja menu.no menu.pl menu.pt menu.ru menu.se menu.sl
    menu.tr menu.zh_CN
    plmenu.da plmenu.de plmenu.fr plmenu.hr plmenu.it)

set(_plain_data
    autostart.sh background.menu background.menu.fy background.menu.nl
    exitscript.sh README README.themes)

set(_prefsdata_files "")
foreach(_f IN LISTS NONGENERATED_MENUS _plain_data)
    list(APPEND _prefsdata_files "${CMAKE_CURRENT_SOURCE_DIR}/${_f}")
endforeach()

wm_stage_files(wmdata_menus
    DESTINATION "${WM_STAGE_PKGDATA}"
    FILES ${_prefsdata_files} ${_generated_menu_files})

# ---------------------------------------------------------------------------
# Global defaults (pkgconfdir)
# ---------------------------------------------------------------------------

wm_expand_file("${CMAKE_CURRENT_SOURCE_DIR}/Defaults/WMWindowAttributes.in"
               "${_gen}/Defaults/WMWindowAttributes"
               "#extension#" "${WM_ICONEXT}")

wm_expand_file("${CMAKE_CURRENT_SOURCE_DIR}/Defaults/WindowMaker.in"
               "${_gen}/Defaults/WindowMaker"
               "#pkgdatadir#" "${WM_PKGDATADIR}"
               "#pixmapdir#"  "${WM_PIXMAPDIR}")

wm_expand_file("${CMAKE_CURRENT_SOURCE_DIR}/Defaults/WMState.in"
               "${_gen}/Defaults/WMState"
               "#wprefs#" "${WM_WPREFSBINDIR}/WPrefs")

# WMRootMenu is simply a copy of the generated plmenu.
wm_copy_file("${_gen}/plmenu" "${_gen}/Defaults/WMRootMenu")

wm_stage_files(wmdata_defaults
    DESTINATION "${WM_STAGE_PKGCONF}"
    FILES
        "${_gen}/Defaults/WMWindowAttributes"
        "${_gen}/Defaults/WindowMaker"
        "${_gen}/Defaults/WMState"
        "${_gen}/Defaults/WMRootMenu"
        "${CMAKE_CURRENT_SOURCE_DIR}/Defaults/WMGLOBAL")

# ---------------------------------------------------------------------------
# Default.iconset is derived from the generated WMWindowAttributes
# ---------------------------------------------------------------------------

wm_grep_lines("${_gen}/Defaults/WMWindowAttributes"
              "${_gen}/IconSets/Default.iconset"
              "Icon"
              PROLOGUE "{\n"
              EPILOGUE "}\n")

wm_stage_files(wmdata_iconsets
    DESTINATION "${WM_STAGE_PKGDATA}/IconSets"
    FILES "${_gen}/IconSets/Default.iconset")

# ---------------------------------------------------------------------------
# Straight data directories
# ---------------------------------------------------------------------------

wm_stage_glob(wmdata_backgrounds
    DESTINATION "${WM_STAGE_PKGDATA}/Backgrounds"
    PATTERNS "${CMAKE_CURRENT_SOURCE_DIR}/Backgrounds/*.jpeg")

wm_stage_glob(wmdata_icons
    DESTINATION "${WM_STAGE_PKGDATA}/Icons"
    PATTERNS
        "${CMAKE_CURRENT_SOURCE_DIR}/Icons/*.tiff"
        "${CMAKE_CURRENT_SOURCE_DIR}/Icons/*.xpm"
        "${CMAKE_CURRENT_SOURCE_DIR}/Icons/*.png")

wm_stage_glob(wmdata_pixmaps
    DESTINATION "${WM_STAGE_PKGDATA}/Pixmaps"
    PATTERNS
        "${CMAKE_CURRENT_SOURCE_DIR}/Pixmaps/*.tiff"
        "${CMAKE_CURRENT_SOURCE_DIR}/Pixmaps/*.xpm"
        "${CMAKE_CURRENT_SOURCE_DIR}/Pixmaps/*.png")

wm_stage_glob(wmdata_styles
    DESTINATION "${WM_STAGE_PKGDATA}/Styles"
    PATTERNS "${CMAKE_CURRENT_SOURCE_DIR}/Styles/*.style")

wm_stage_glob(wmdata_themes
    DESTINATION "${WM_STAGE_PKGDATA}/Themes"
    PATTERNS "${CMAKE_CURRENT_SOURCE_DIR}/Themes/*.style")

# ---------------------------------------------------------------------------
# XSession entry
# ---------------------------------------------------------------------------

wm_stage_files(wmdata_xsessions
    DESTINATION "${WM_STAGE_SHARE}/xsessions"
    FILES "${CMAKE_CURRENT_SOURCE_DIR}/wmaker.desktop")

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------

install(FILES ${_prefsdata_files} ${_generated_menu_files}
        DESTINATION ${WM_PKGDATADIR})
install(DIRECTORY "${WM_STAGE_PKGDATA}/Backgrounds" "${WM_STAGE_PKGDATA}/Icons"
                  "${WM_STAGE_PKGDATA}/Pixmaps" "${WM_STAGE_PKGDATA}/Styles"
                  "${WM_STAGE_PKGDATA}/Themes" "${WM_STAGE_PKGDATA}/IconSets"
        DESTINATION ${WM_PKGDATADIR}
        OPTIONAL)
install(FILES
            "${_gen}/Defaults/WMWindowAttributes"
            "${_gen}/Defaults/WindowMaker"
            "${_gen}/Defaults/WMState"
            "${_gen}/Defaults/WMRootMenu"
            "${CMAKE_CURRENT_SOURCE_DIR}/Defaults/WMGLOBAL"
        DESTINATION ${WM_PKGCONFDIR})
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/wmaker.desktop"
        DESTINATION ${WM_DATAROOTDIR}/xsessions)
