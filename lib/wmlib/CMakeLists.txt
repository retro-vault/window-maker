# libWMaker - the client-side library for talking to Window Maker's app menus.

add_library(WMaker
    menu.c
    app.c
    event.c
    command.c)

set_target_properties(WMaker PROPERTIES VERSION 1.0.1 SOVERSION 1)

target_include_directories(WMaker
    PUBLIC "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>"
    PRIVATE ${X11_INCLUDE_DIR})

target_link_libraries(WMaker PRIVATE ${X11_LIBRARIES})

add_custom_command(TARGET WMaker POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory "${WM_STAGE_INCLUDE}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CMAKE_CURRENT_SOURCE_DIR}/WMaker.h" "${WM_STAGE_INCLUDE}/WMaker.h"
    COMMENT "Staging WMaker.h")

configure_file("${CMAKE_SOURCE_DIR}/cmake/wmlib.pc.in"
               "${WM_STAGE_LIB}/pkgconfig/wmlib.pc" @ONLY)

install(TARGETS WMaker
        LIBRARY DESTINATION ${WM_LIBDIR}
        ARCHIVE DESTINATION ${WM_LIBDIR})
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/WMaker.h"
        DESTINATION ${WM_INCLUDEDIR})
install(FILES "${WM_STAGE_LIB}/pkgconfig/wmlib.pc"
        DESTINATION ${WM_LIBDIR}/pkgconfig)

# Demo clients for this library.
if(WMAKER_BUILD_EXAMPLES)
    add_subdirectory(test)
endif()
