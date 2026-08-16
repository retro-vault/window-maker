# WINGs - the NeXTStep-like widget set, plus WUtil, its toolkit-free half.

# ---------------------------------------------------------------------------
# Generated private header
# ---------------------------------------------------------------------------

if(USE_PANGO)
    wm_filter_template("${CMAKE_CURRENT_SOURCE_DIR}/WINGs/WINGsP.h.in"
                       "${WM_GENERATED_DIR}/WINGs/WINGsP.h" ENABLED USE_PANGO)
else()
    wm_filter_template("${CMAKE_CURRENT_SOURCE_DIR}/WINGs/WINGsP.h.in"
                       "${WM_GENERATED_DIR}/WINGs/WINGsP.h" DISABLED USE_PANGO)
endif()

# ---------------------------------------------------------------------------
# libWUtil - no X11 dependency: arrays, hashes, proplists, notifications...
# ---------------------------------------------------------------------------

set(WUTIL_SOURCES
    array.c
    bagtree.c
    data.c
    error.c
    findfile.c
    handlers.c
    hashtable.c
    memory.c
    menuparser.c
    menuparser_macros.c
    misc.c
    notification.c
    proplist.c
    string.c
    tree.c
    userdefaults.c
    usleep.c
    wapplication.c
    wutil.c)

add_library(WUtil ${WUTIL_SOURCES})
add_library(WindowMaker::WUtil ALIAS WUtil)

set_target_properties(WUtil PROPERTIES VERSION 5.0.0 SOVERSION 5)

target_include_directories(WUtil PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
target_compile_definitions(WUtil PRIVATE RESOURCE_PATH="${WM_WINGSDATADIR}")
target_link_libraries(WUtil PUBLIC wmaker_common)

# ---------------------------------------------------------------------------
# libWINGs - the widgets themselves
# ---------------------------------------------------------------------------

set(WINGS_SOURCES
    configuration.c
    dragcommon.c
    dragdestination.c
    dragsource.c
    selection.c
    wappresource.c
    wballoon.c
    wbox.c
    wbrowser.c
    wbutton.c
    wcolor.c
    wcolorpanel.c
    wcolorwell.c
    wevent.c
    wfilepanel.c
    wframe.c
    wfont.c
    wfontpanel.c
    widgets.c
    winputmethod.c
    wlabel.c
    wlist.c
    wmenuitem.c
    wmisc.c
    wpanel.c
    wpixmap.c
    wpopupbutton.c
    wprogressindicator.c
    wruler.c
    wscroller.c
    wscrollview.c
    wslider.c
    wsplitview.c
    wtabview.c
    wtext.c
    wtextfield.c
    wview.c
    wwindow.c)

add_library(WINGs ${WINGS_SOURCES} "${WM_GENERATED_DIR}/WINGs/WINGsP.h")
add_library(WindowMaker::WINGs ALIAS WINGs)

set_target_properties(WINGs PROPERTIES VERSION 3.2.0 SOVERSION 3)

target_include_directories(WINGs
    PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}" "${CMAKE_SOURCE_DIR}/src/wmaker")
target_compile_definitions(WINGs PRIVATE RESOURCE_PATH="${WM_WINGSDATADIR}")

target_link_libraries(WINGs
    PUBLIC  wmaker_common
    PRIVATE WUtil wraster
            PkgConfig::XFT PkgConfig::FONTCONFIG ${WM_PANGO_LIBS}
            ${WM_XEXT_LIBS} ${X11_LIBRARIES} ${WM_LIBM})

# ---------------------------------------------------------------------------
# Public headers, staged so out-of-tree WINGs programs can just -I bin/include
# ---------------------------------------------------------------------------

add_custom_target(WINGs_headers ALL
    COMMAND ${CMAKE_COMMAND} -E make_directory "${WM_STAGE_INCLUDE}/WINGs"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CMAKE_CURRENT_SOURCE_DIR}/WINGs/WINGs.h" "${WM_STAGE_INCLUDE}/WINGs/WINGs.h"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CMAKE_CURRENT_SOURCE_DIR}/WINGs/WUtil.h" "${WM_STAGE_INCLUDE}/WINGs/WUtil.h"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${WM_GENERATED_DIR}/WINGs/WINGsP.h" "${WM_STAGE_INCLUDE}/WINGs/WINGsP.h"
    DEPENDS "${WM_GENERATED_DIR}/WINGs/WINGsP.h"
    COMMENT "Staging WINGs headers")

add_dependencies(WINGs WINGs_headers)

# ---------------------------------------------------------------------------
# pkg-config files
# ---------------------------------------------------------------------------

configure_file("${CMAKE_SOURCE_DIR}/cmake/WINGs.pc.in"
               "${WM_STAGE_LIB}/pkgconfig/WINGs.pc" @ONLY)
configure_file("${CMAKE_SOURCE_DIR}/cmake/WUtil.pc.in"
               "${WM_STAGE_LIB}/pkgconfig/WUtil.pc" @ONLY)

# ---------------------------------------------------------------------------
# Test / example programs - the quickest way to see the widgets in action
# ---------------------------------------------------------------------------

if(WMAKER_BUILD_EXAMPLES)
    add_subdirectory(Tests)
    add_subdirectory(Examples)
    add_subdirectory(Extras)
endif()

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------

install(TARGETS WINGs WUtil
        LIBRARY DESTINATION ${WM_LIBDIR}
        ARCHIVE DESTINATION ${WM_LIBDIR})
install(FILES
            "${CMAKE_CURRENT_SOURCE_DIR}/WINGs/WINGs.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/WINGs/WUtil.h"
            "${WM_GENERATED_DIR}/WINGs/WINGsP.h"
        DESTINATION ${WM_INCLUDEDIR}/WINGs)
install(FILES
            "${WM_STAGE_LIB}/pkgconfig/WINGs.pc"
            "${WM_STAGE_LIB}/pkgconfig/WUtil.pc"
        DESTINATION ${WM_LIBDIR}/pkgconfig)
