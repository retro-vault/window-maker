# Manual pages.
#
# Most are plain files; wmaker.1 and wmsetbg.1 document options that only exist
# in some configurations, so they are generated from templates against the
# feature flags - the same way the sources' generated headers are.

set(_gen "${CMAKE_BINARY_DIR}/generated/doc")

set(WMAKER_MAN_PAGES
    geticonset.1
    getstyle.1
    seticons.1
    setstyle.1
    wdread.1
    wdwrite.1
    WindowMaker.1
    wmagnify.1
    wmgenmenu.1
    wmiv.1
    wmmenugen.1
    WPrefs.1
    wxcopy.1
    wxpaste.1)

set(_man_files "")
foreach(_page IN LISTS WMAKER_MAN_PAGES)
    list(APPEND _man_files "${CMAKE_CURRENT_SOURCE_DIR}/${_page}")
endforeach()

# --- wmaker.1 -------------------------------------------------------------

set(_wmaker_enabled "")
set(_wmaker_disabled "")
foreach(_key HAVE_INOTIFY USE_ICCCM_WMREPLACE)
    if(${_key})
        list(APPEND _wmaker_enabled ${_key})
    else()
        list(APPEND _wmaker_disabled ${_key})
    endif()
endforeach()

wm_filter_template("${CMAKE_CURRENT_SOURCE_DIR}/wmaker.in" "${_gen}/wmaker.1.filtered"
                   ENABLED ${_wmaker_enabled} DISABLED ${_wmaker_disabled})
wm_expand_file("${_gen}/wmaker.1.filtered" "${_gen}/wmaker.1"
               "@pkgdatadir@" "${WM_PKGDATADIR}"
               "@pkgconfdir@" "${WM_PKGCONFDIR}")

# --- wmsetbg.1 ------------------------------------------------------------

if(USE_XINERAMA)
    wm_filter_template("${CMAKE_CURRENT_SOURCE_DIR}/wmsetbg.in" "${_gen}/wmsetbg.1"
                       ENABLED USE_XINERAMA)
else()
    wm_filter_template("${CMAKE_CURRENT_SOURCE_DIR}/wmsetbg.in" "${_gen}/wmsetbg.1"
                       DISABLED USE_XINERAMA)
endif()

list(APPEND _man_files "${_gen}/wmaker.1" "${_gen}/wmsetbg.1")

wm_stage_files(man_pages
    DESTINATION "${WM_STAGE_SHARE}/man/man1"
    FILES ${_man_files})

install(FILES ${_man_files} DESTINATION "${WM_DATAROOTDIR}/man/man1")

# --- translated pages -----------------------------------------------------

foreach(_lang cs ru sk)
    file(GLOB _translated CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/${_lang}/*.1")
    if(_translated)
        wm_stage_files(man_pages_${_lang}
            DESTINATION "${WM_STAGE_SHARE}/man/${_lang}/man1"
            FILES ${_translated})
        install(FILES ${_translated} DESTINATION "${WM_DATAROOTDIR}/man/${_lang}/man1")
    endif()
endforeach()
