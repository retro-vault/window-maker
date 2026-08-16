# Widget artwork libWINGs loads at startup from RESOURCE_PATH.
#
# Both the TIFF and XPM sets are staged; which one is read at run time depends
# on whether the build found libtiff.

set(WINGS_RESOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/Images.tiff"
    "${CMAKE_CURRENT_SOURCE_DIR}/Images.xpm"
    "${CMAKE_CURRENT_SOURCE_DIR}/defaultIcon.tiff"
    "${CMAKE_CURRENT_SOURCE_DIR}/defaultIcon.xpm")

wm_stage_files(WINGs_resources
    DESTINATION "${WM_STAGE_WINGSDATA}"
    FILES ${WINGS_RESOURCES})

# libWINGs is useless without these, so make the dependency explicit.
add_dependencies(WINGs WINGs_resources)

install(FILES ${WINGS_RESOURCES} DESTINATION ${WM_WINGSDATADIR})
