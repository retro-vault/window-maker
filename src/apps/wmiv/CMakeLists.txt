# wmiv - a quick image viewer built on wrlib.

add_executable(wmiv wmiv.c)

target_include_directories(wmiv PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")

target_compile_definitions(wmiv PRIVATE
    ETCDIR="${WM_SYSCONFDIR}"
    DATADIR="${WM_PKGDATADIR}")

target_link_libraries(wmiv PRIVATE
    wmaker_common wraster WINGs WUtil
    ${WM_GFX_LIBS} ${WM_PANGO_LIBS} ${WM_EXIF_LIBS}
    ${X11_LIBRARIES} Threads::Threads)

install(TARGETS wmiv RUNTIME DESTINATION ${WM_BINDIR})
