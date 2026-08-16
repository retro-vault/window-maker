# libwraster - image loading, conversion and rendering.

set(WRASTER_SOURCES
    raster.c
    alpha_combine.c
    draw.c
    color.c
    load.c
    save.c
    gradient.c
    xpixmap.c
    convert.c
    context.c
    misc.c
    scale.c
    rotate.c
    flip.c
    convolve.c
    save_xpm.c
    xutil.c
    load_ppm.c)

if(USE_GIF)
    list(APPEND WRASTER_SOURCES load_gif.c)
endif()
if(USE_JPEG)
    list(APPEND WRASTER_SOURCES load_jpeg.c save_jpeg.c)
endif()
if(USE_PNG)
    list(APPEND WRASTER_SOURCES load_png.c save_png.c)
endif()
if(USE_TIFF)
    list(APPEND WRASTER_SOURCES load_tiff.c)
endif()
if(USE_XPM)
    list(APPEND WRASTER_SOURCES load_xpm.c)
else()
    list(APPEND WRASTER_SOURCES load_xpm_normalized.c)
endif()
if(USE_WEBP)
    list(APPEND WRASTER_SOURCES load_webp.c)
endif()
if(USE_MAGICK)
    list(APPEND WRASTER_SOURCES load_magick.c)
endif()

# wraster.h is a public header whose XShm bits depend on the configuration.
if(USE_XSHM)
    wm_filter_template("${CMAKE_CURRENT_SOURCE_DIR}/wraster.h.in"
                       "${WM_GENERATED_DIR}/wraster.h" ENABLED USE_XSHM)
else()
    wm_filter_template("${CMAKE_CURRENT_SOURCE_DIR}/wraster.h.in"
                       "${WM_GENERATED_DIR}/wraster.h" DISABLED USE_XSHM)
endif()

add_library(wraster ${WRASTER_SOURCES} "${WM_GENERATED_DIR}/wraster.h")
add_library(WindowMaker::wraster ALIAS wraster)

set_target_properties(wraster PROPERTIES
    OUTPUT_NAME wraster
    VERSION 6.1.0
    SOVERSION 6)

target_include_directories(wraster
    PUBLIC
        "$<BUILD_INTERFACE:${WM_GENERATED_DIR}>"
        "$<INSTALL_INTERFACE:${WM_INCLUDEDIR}>"
    PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}")

target_link_libraries(wraster
    PUBLIC  wmaker_common
    PRIVATE ${WM_GFX_LIBS} ${WM_XEXT_LIBS} ${X11_LIBRARIES} ${WM_LIBM})

if(HAVE_LIBXMU)
    target_link_libraries(wraster PRIVATE ${X11_Xmu_LIB})
endif()

# Public headers staged next to the libraries.
add_custom_command(TARGET wraster POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory "${WM_STAGE_INCLUDE}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${WM_GENERATED_DIR}/wraster.h" "${WM_STAGE_INCLUDE}/wraster.h"
    COMMENT "Staging wraster.h")

configure_file("${CMAKE_SOURCE_DIR}/cmake/wrlib.pc.in"
               "${WM_STAGE_LIB}/pkgconfig/wrlib.pc" @ONLY)

install(TARGETS wraster
        LIBRARY DESTINATION ${WM_LIBDIR}
        ARCHIVE DESTINATION ${WM_LIBDIR})
install(FILES "${WM_GENERATED_DIR}/wraster.h"
        DESTINATION ${WM_INCLUDEDIR})
install(FILES "${WM_STAGE_LIB}/pkgconfig/wrlib.pc"
        DESTINATION ${WM_LIBDIR}/pkgconfig)

# Demo/regression programs for the library.
if(WMAKER_BUILD_EXAMPLES)
    add_subdirectory(tests)
endif()
