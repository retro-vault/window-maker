# wmagnify - magnifies the area around the mouse pointer, updating live.

add_executable(wmagnify wmagnify.c)

target_include_directories(wmagnify PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")

target_compile_definitions(wmagnify PRIVATE
    ETCDIR="${WM_SYSCONFDIR}"
    DATADIR="${WM_PKGDATADIR}")

target_link_libraries(wmagnify PRIVATE
    wmaker_common WINGs WUtil wraster ${X11_LIBRARIES})

install(TARGETS wmagnify RUNTIME DESTINATION ${WM_BINDIR})
