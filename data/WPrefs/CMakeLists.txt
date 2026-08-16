# WPrefs panel icons, read at run time from RESOURCE_PATH.
#
# Both icon sets are staged; which one WPrefs reads depends on whether the
# build found libtiff.

wm_stage_files(wprefs_data
    DESTINATION "${WM_STAGE_WPREFSDATA}"
    FILES
        "${CMAKE_CURRENT_SOURCE_DIR}/WPrefs.tiff"
        "${CMAKE_CURRENT_SOURCE_DIR}/WPrefs.xpm")

wm_stage_glob(wprefs_tiff
    DESTINATION "${WM_STAGE_WPREFSDATA}/tiff"
    PATTERNS "${CMAKE_CURRENT_SOURCE_DIR}/tiff/*.tiff")

wm_stage_glob(wprefs_xpm
    DESTINATION "${WM_STAGE_WPREFSDATA}/xpm"
    PATTERNS "${CMAKE_CURRENT_SOURCE_DIR}/xpm/*.xpm")

add_dependencies(WPrefs wprefs_data wprefs_tiff wprefs_xpm)

install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/WPrefs.tiff"
              "${CMAKE_CURRENT_SOURCE_DIR}/WPrefs.xpm"
        DESTINATION ${WM_WPREFSDATADIR})
install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/tiff"
                  "${CMAKE_CURRENT_SOURCE_DIR}/xpm"
        DESTINATION ${WM_WPREFSDATADIR}
        FILES_MATCHING PATTERN "*.tiff" PATTERN "*.xpm")
