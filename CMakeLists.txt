cmake_minimum_required(VERSION 3.16)
project(WindowMaker VERSION 0.96.0 LANGUAGES C)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

include(WMakerHelpers)
include(CheckCSourceCompiles)
include(CheckIncludeFile)
include(CheckSymbolExists)
include(CMakePushCheckState)
include(GNUInstallDirs)

set(WM_PACKAGE_NAME       "WindowMaker")
set(WM_PACKAGE_TARNAME    "WindowMaker")
set(WM_PACKAGE_BUGREPORT  "wmaker-dev@googlegroups.com")
set(WM_PACKAGE_URL        "http://www.windowmaker.org/")

# Use Debug as default if none is specified: this tree is meant for hacking.
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "Choose the type of build." FORCE)
endif()

# The sources use GNU C extensions (nested functions, statement expressions),
# so gnu11 rather than plain c11.
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

option(BUILD_SHARED_LIBS "Build wrlib/WINGs/WUtil/wmlib as shared libraries" ON)

# ---------------------------------------------------------------------------
# Staged tree layout
#
# Every artifact lands in <repo>/bin, laid out exactly like an install prefix,
# while object files stay in the build tree.  Two independent sets of paths are
# involved and it matters that they stay separate:
#
#   WM_STAGE_*  where the build writes things.  Always the staged tree.
#   WM_*DIR     the paths compiled into the binaries (PKGDATADIR & co) and
#               written into the generated menus and .pc files.
#
# With WMAKER_DEV_TREE=ON (the default) the two coincide and the stage is
# <repo>/bin, which is what makes "run it straight from the checkout" work.
# Turn it off to bake in the install prefix instead; the stage then moves to
# <builddir>/stage so it cannot overwrite a development tree, and
# `cmake --install` copies from there.
#
# Because the paths are compiled in, every install() destination below is the
# absolute WM_*DIR path rather than a GNUInstallDirs-relative one - otherwise a
# prefix such as /opt/wmaker would install the global defaults to
# <prefix>/etc/WindowMaker while the binary looked in /etc/opt/wmaker/WindowMaker.
# The consequence is that `cmake --install --prefix` cannot relocate: choose the
# prefix at configure time with -DCMAKE_INSTALL_PREFIX.  DESTDIR still works for
# packaging.
# ---------------------------------------------------------------------------

option(WMAKER_DEV_TREE "Bake the staged tree's paths into the binaries" ON)
set(WMAKER_STAGE_DIR "" CACHE PATH
    "Staging prefix; empty means <repo>/bin for a dev tree, <builddir>/stage otherwise")

# A non-dev build must not stage into <repo>/bin: its binaries have the install
# prefix compiled in, so dropping them there would silently replace a working
# development tree with one that looks for its data under the install prefix.
if(WMAKER_STAGE_DIR)
    set(WM_STAGE_PREFIX "${WMAKER_STAGE_DIR}")
elseif(WMAKER_DEV_TREE)
    set(WM_STAGE_PREFIX "${CMAKE_SOURCE_DIR}/bin")
else()
    set(WM_STAGE_PREFIX "${CMAKE_BINARY_DIR}/stage")
endif()
set(WM_STAGE_BIN        "${WM_STAGE_PREFIX}/bin")
set(WM_STAGE_LIB        "${WM_STAGE_PREFIX}/lib")
set(WM_STAGE_INCLUDE    "${WM_STAGE_PREFIX}/include")
set(WM_STAGE_SHARE      "${WM_STAGE_PREFIX}/share")
set(WM_STAGE_ETC        "${WM_STAGE_PREFIX}/etc")
set(WM_STAGE_PKGDATA    "${WM_STAGE_SHARE}/${WM_PACKAGE_TARNAME}")
set(WM_STAGE_PKGCONF    "${WM_STAGE_ETC}/${WM_PACKAGE_TARNAME}")
set(WM_STAGE_LOCALE     "${WM_STAGE_SHARE}/locale")
set(WM_STAGE_WINGSDATA  "${WM_STAGE_SHARE}/WINGs")
set(WM_STAGE_WPREFSDATA "${WM_STAGE_SHARE}/WPrefs")

if(WMAKER_DEV_TREE)
    set(WM_PREFIX      "${WM_STAGE_PREFIX}")
    set(WM_BINDIR      "${WM_STAGE_BIN}")
    set(WM_LIBDIR      "${WM_STAGE_LIB}")
    set(WM_INCLUDEDIR  "${WM_STAGE_INCLUDE}")
    set(WM_DATAROOTDIR "${WM_STAGE_SHARE}")
    set(WM_SYSCONFDIR  "${WM_STAGE_ETC}")
else()
    set(WM_PREFIX      "${CMAKE_INSTALL_PREFIX}")
    set(WM_BINDIR      "${CMAKE_INSTALL_FULL_BINDIR}")
    set(WM_LIBDIR      "${CMAKE_INSTALL_FULL_LIBDIR}")
    set(WM_INCLUDEDIR  "${CMAKE_INSTALL_FULL_INCLUDEDIR}")
    set(WM_DATAROOTDIR "${CMAKE_INSTALL_FULL_DATAROOTDIR}")
    set(WM_SYSCONFDIR  "${CMAKE_INSTALL_FULL_SYSCONFDIR}")
endif()

set(WM_PKGDATADIR    "${WM_DATAROOTDIR}/${WM_PACKAGE_TARNAME}")
set(WM_PKGCONFDIR    "${WM_SYSCONFDIR}/${WM_PACKAGE_TARNAME}")
set(WM_LOCALEDIR     "${WM_DATAROOTDIR}/locale")
set(WM_PIXMAPDIR     "${WM_DATAROOTDIR}/pixmaps")
set(WM_WINGSDATADIR  "${WM_DATAROOTDIR}/WINGs")
set(WM_WPREFSDATADIR "${WM_DATAROOTDIR}/WPrefs")
set(WM_WPREFSBINDIR  "${WM_BINDIR}")

# Where build artifacts are written.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${WM_STAGE_BIN}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${WM_STAGE_LIB}")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${WM_STAGE_LIB}")
foreach(cfg DEBUG RELEASE RELWITHDEBINFO MINSIZEREL)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${cfg} "${WM_STAGE_BIN}")
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${cfg} "${WM_STAGE_LIB}")
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${cfg} "${WM_STAGE_LIB}")
endforeach()

# Generated headers (config.h, wraster.h, WINGsP.h) live here.
set(WM_GENERATED_DIR "${CMAKE_BINARY_DIR}/generated")
file(MAKE_DIRECTORY "${WM_GENERATED_DIR}")
file(MAKE_DIRECTORY "${WM_GENERATED_DIR}/WINGs")

# The staged binaries find the staged libraries without LD_LIBRARY_PATH;
# installed ones get the install libdir instead.
set(CMAKE_BUILD_RPATH "${WM_STAGE_LIB}")
set(CMAKE_INSTALL_RPATH "${WM_LIBDIR}")
set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

# ---------------------------------------------------------------------------
# Feature options (defaults follow configure.ac)
# ---------------------------------------------------------------------------

option(WMAKER_ANIMATIONS   "Enable animations"                             ON)
option(WMAKER_MWM_HINTS    "Support Motif WM hints"                        ON)
option(WMAKER_XDND         "Support drag-and-drop onto the dock"           ON)
option(WMAKER_MODELOCK     "Support XKB language modelock"                 OFF)
option(WMAKER_WMREPLACE    "Support the ICCCM window-manager replace protocol" OFF)
option(WMAKER_USERMENU     "Support per-application user menus"            OFF)
option(WMAKER_RANDR        "Use the RandR extension"                       ON)
option(WMAKER_PANGO        "Use Pango for text layout in WINGs"            OFF)
option(WMAKER_NLS          "Compile and install translations"              ON)

option(WMAKER_BUILD_WPREFS   "Build the WPrefs application"                            ON)
option(WMAKER_BUILD_UTILS    "Build the command-line utilities"            ON)
option(WMAKER_BUILD_WMLIB    "Build libWMaker (wmlib)"                     ON)
option(WMAKER_BUILD_EXAMPLES "Build the WINGs test and example programs"   ON)

# ---------------------------------------------------------------------------
# Required dependencies
# ---------------------------------------------------------------------------

find_package(X11 REQUIRED)
if(NOT X11_FOUND)
    message(FATAL_ERROR "X11 development files are required")
endif()

find_library(WM_LIBM m)
if(NOT WM_LIBM)
    set(WM_LIBM "")
endif()

# ---------------------------------------------------------------------------
# X extensions
# ---------------------------------------------------------------------------

set(USE_XSHAPE ${X11_Xshape_FOUND})
set(USE_XSHM ${X11_XShm_FOUND})
set(HAVE_LIBXMU ${X11_Xmu_FOUND})
set(USE_XPM ${X11_Xpm_FOUND})

set(USE_XINERAMA ${X11_Xinerama_FOUND})
if(USE_XINERAMA AND NOT X11_Xinerama_LIB)
    set(USE_XINERAMA FALSE)
endif()

set(USE_XRES FALSE)
if(X11_Xres_FOUND AND X11_Xres_LIB)
    set(USE_XRES TRUE)
endif()

set(USE_RANDR FALSE)
if(WMAKER_RANDR)
    if(X11_Xrandr_FOUND)
        set(USE_RANDR TRUE)
    else()
        message(WARNING "RandR requested but libXrandr was not found; disabling")
    endif()
endif()

# X11::Xshape / XShm are part of libXext.
set(WM_XEXT_LIBS "")
if(USE_XSHAPE OR USE_XSHM)
    list(APPEND WM_XEXT_LIBS ${X11_Xext_LIB})
endif()
if(USE_XINERAMA)
    list(APPEND WM_XEXT_LIBS ${X11_Xinerama_LIB})
endif()
if(USE_RANDR)
    list(APPEND WM_XEXT_LIBS ${X11_Xrandr_LIB})
endif()
if(USE_XRES)
    list(APPEND WM_XEXT_LIBS ${X11_Xres_LIB})
endif()
list(REMOVE_DUPLICATES WM_XEXT_LIBS)

# ---------------------------------------------------------------------------
# Image format libraries (auto-detected, like configure's "auto" default)
# ---------------------------------------------------------------------------

set(WM_GFX_LIBS "")

find_package(PNG)
set(USE_PNG ${PNG_FOUND})
if(USE_PNG)
    list(APPEND WM_GFX_LIBS PNG::PNG)
endif()

find_package(JPEG)
set(USE_JPEG ${JPEG_FOUND})
if(USE_JPEG)
    list(APPEND WM_GFX_LIBS JPEG::JPEG)
endif()

find_package(TIFF)
set(USE_TIFF ${TIFF_FOUND})
if(USE_TIFF)
    list(APPEND WM_GFX_LIBS TIFF::TIFF)
endif()

find_package(GIF)
set(USE_GIF ${GIF_FOUND})
if(USE_GIF)
    list(APPEND WM_GFX_LIBS GIF::GIF)
endif()

find_package(PkgConfig)
set(USE_WEBP FALSE)
if(PKG_CONFIG_FOUND)
    pkg_check_modules(WEBP IMPORTED_TARGET libwebp)
    if(WEBP_FOUND)
        set(USE_WEBP TRUE)
        list(APPEND WM_GFX_LIBS PkgConfig::WEBP)
    endif()
endif()

if(USE_XPM)
    list(APPEND WM_GFX_LIBS ${X11_Xpm_LIB})
endif()

# ImageMagick's MagickWand is opt-in: it pulls in a lot and is rarely wanted
# for a development tree.
option(WMAKER_MAGICK "Use MagickWand for extra image formats" OFF)
set(USE_MAGICK FALSE)
if(WMAKER_MAGICK AND PKG_CONFIG_FOUND)
    pkg_check_modules(MAGICKWAND IMPORTED_TARGET MagickWand)
    if(MAGICKWAND_FOUND)
        set(USE_MAGICK TRUE)
        list(APPEND WM_GFX_LIBS PkgConfig::MAGICKWAND)
    else()
        message(WARNING "MagickWand requested but not found; disabling")
    endif()
endif()

if(USE_TIFF)
    set(WM_ICONEXT "tiff")
else()
    set(WM_ICONEXT "xpm")
endif()

# ---------------------------------------------------------------------------
# Xft / fontconfig / Pango
# ---------------------------------------------------------------------------

if(NOT PKG_CONFIG_FOUND)
    message(FATAL_ERROR "pkg-config is required to locate Xft and fontconfig")
endif()

pkg_check_modules(XFT REQUIRED IMPORTED_TARGET xft)
pkg_check_modules(FONTCONFIG REQUIRED IMPORTED_TARGET fontconfig)

set(USE_PANGO FALSE)
set(WM_PANGO_LIBS "")
if(WMAKER_PANGO)
    pkg_check_modules(PANGOXFT IMPORTED_TARGET pangoxft)
    if(PANGOXFT_FOUND)
        set(USE_PANGO TRUE)
        set(WM_PANGO_LIBS PkgConfig::PANGOXFT)
    else()
        message(WARNING "Pango requested but pangoxft was not found; disabling")
    endif()
endif()

# ---------------------------------------------------------------------------
# libexif (used by wmiv for JPEG orientation)
# ---------------------------------------------------------------------------

set(HAVE_EXIF FALSE)
set(WM_EXIF_LIBS "")
pkg_check_modules(LIBEXIF IMPORTED_TARGET libexif)
if(LIBEXIF_FOUND)
    set(HAVE_EXIF TRUE)
    set(WM_EXIF_LIBS PkgConfig::LIBEXIF)
endif()

# ---------------------------------------------------------------------------
# Threads (wmiv)
# ---------------------------------------------------------------------------

set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads)
set(HAVE_PTHREAD ${CMAKE_USE_PTHREADS_INIT})
set(HAVE_PTHREAD_PRIO_INHERIT FALSE)

# ---------------------------------------------------------------------------
# Header / function probes
# ---------------------------------------------------------------------------

foreach(_hdr bsd/string.h ctype.h dlfcn.h fcntl.h inttypes.h libintl.h limits.h
             malloc.h poll.h stdint.h stdio.h stdlib.h strings.h string.h
             syslog.h sys/inotify.h sys/ioctl.h sys/stat.h sys/types.h
             sys/wait.h unistd.h)
    string(TOUPPER "${_hdr}" _var)
    string(REGEX REPLACE "[./]" "_" _var "${_var}")
    check_include_file("${_hdr}" HAVE_${_var})
endforeach()

set(STDC_HEADERS TRUE)
set(HAVE_SYSLOG ${HAVE_SYSLOG_H})
set(HAVE_INOTIFY ${HAVE_SYS_INOTIFY_H})

cmake_push_check_state()
set(CMAKE_REQUIRED_DEFINITIONS -D_GNU_SOURCE)

check_symbol_exists(gethostname   "unistd.h"             HAVE_GETHOSTNAME)
check_symbol_exists(mkstemp       "stdlib.h"             HAVE_MKSTEMP)
check_symbol_exists(poll          "poll.h"               HAVE_POLL)
check_symbol_exists(select        "sys/select.h"         HAVE_SELECT)
check_symbol_exists(setsid        "unistd.h"             HAVE_SETSID)
check_symbol_exists(sysconf       "unistd.h"             HAVE_SYSCONF)
check_symbol_exists(strcasecmp    "strings.h"            HAVE_STRCASECMP)
check_symbol_exists(strncasecmp   "strings.h"            HAVE_STRNCASECMP)
check_symbol_exists(vprintf       "stdio.h"              HAVE_VPRINTF)
check_symbol_exists(secure_getenv "stdlib.h"             HAVE_SECURE_GETENV)
check_symbol_exists(mallinfo2     "malloc.h"             HAVE_MALLINFO2)
check_symbol_exists(strlcat       "string.h"             HAVE_STRLCAT)
check_symbol_exists(gettext       "libintl.h"            HAVE_GETTEXT)
check_symbol_exists(dgettext      "libintl.h"            HAVE_DGETTEXT)

cmake_pop_check_state()

# 'float'-typed math functions
cmake_push_check_state()
list(APPEND CMAKE_REQUIRED_LIBRARIES m)
check_c_source_compiles("
#include <math.h>
int main(void) { float a = 0.5f; return (int)(sinf(a) + cosf(a) + atan2f(a, a)); }
" HAVE_FLOAT_MATHFUNC)

# M_PI is not in ISO C; configure falls back to a literal when it is missing.
check_c_source_compiles("
#include <math.h>
int main(void) { double a = M_PI; return (int)a; }
" WM_HAVE_M_PI)
cmake_pop_check_state()

if(WM_HAVE_M_PI)
    set(WM_PI_VALUE "(M_PI)")
else()
    set(WM_PI_VALUE "(3.14159265358979323846)")
endif()

check_c_source_compiles("
#include <stdnoreturn.h>
noreturn void f(void) { for (;;); }
int main(void) { return 0; }
" HAVE_STDNORETURN)

if(HAVE_STDNORETURN)
    set(WM_NORETURN_ATTRIBUTE "")
else()
    check_c_source_compiles("
    __attribute__((__noreturn__)) void f(void) { for (;;); }
    int main(void) { return 0; }
    " WM_HAVE_ATTRIBUTE_NORETURN)
    if(WM_HAVE_ATTRIBUTE_NORETURN)
        set(WM_NORETURN_ATTRIBUTE "__attribute__((__noreturn__))")
    else()
        set(WM_NORETURN_ATTRIBUTE "")
    endif()
endif()

check_c_source_compiles("
static void __attribute__((constructor)) init_me(void) { }
int main(void) { return 0; }
" WM_HAVE_ATTRIBUTE_CONSTRUCTOR)

if(WM_HAVE_ATTRIBUTE_CONSTRUCTOR)
    set(WM_LIB_CONSTRUCTOR "__attribute__ ((constructor)) func_name")
else()
    set(WM_LIB_CONSTRUCTOR "_init")
endif()

check_c_source_compiles("
#include <fcntl.h>
int main(void) { return O_NOFOLLOW; }
" WM_HAVE_O_NOFOLLOW)

if(WM_HAVE_O_NOFOLLOW)
    set(WM_DEFINE_O_NOFOLLOW "/* O_NOFOLLOW comes from <fcntl.h> */")
else()
    set(WM_DEFINE_O_NOFOLLOW "#define O_NOFOLLOW 0")
endif()

cmake_push_check_state()
set(CMAKE_REQUIRED_INCLUDES ${X11_INCLUDE_DIR})
set(CMAKE_REQUIRED_LIBRARIES ${X11_LIBRARIES})
check_symbol_exists(XConvertCase "X11/Xlib.h;X11/Xutil.h" HAVE_XCONVERTCASE)
check_symbol_exists(XInternAtoms "X11/Xlib.h" HAVE_XINTERNATOMS)
cmake_pop_check_state()

# ---------------------------------------------------------------------------
# Feature defines
# ---------------------------------------------------------------------------

set(USE_ANIMATIONS      ${WMAKER_ANIMATIONS})
set(USE_MWM_HINTS       ${WMAKER_MWM_HINTS})
set(USE_DOCK_XDND       ${WMAKER_XDND})
set(XKB_MODELOCK        ${WMAKER_MODELOCK})
set(USE_ICCCM_WMREPLACE ${WMAKER_WMREPLACE})
set(USER_MENU           ${WMAKER_USERMENU})

# ---------------------------------------------------------------------------
# Translations
# ---------------------------------------------------------------------------

# Menus normally use the main WindowMaker catalogue.  A distribution that
# customises the menus can point them at a catalogue of its own instead; this
# mirrors configure's --with-menu-textdomain, which is likewise off by default.
set(WMAKER_MENU_TEXTDOMAIN "" CACHE STRING
    "gettext domain for menu translations (empty: use the default domain)")

set(I18N FALSE)
set(MENU_TEXTDOMAIN "${WMAKER_MENU_TEXTDOMAIN}")
if(WMAKER_NLS)
    find_program(MSGFMT_EXECUTABLE msgfmt)
    if(MSGFMT_EXECUTABLE AND HAVE_LIBINTL_H AND HAVE_GETTEXT)
        set(I18N TRUE)
    else()
        message(STATUS "NLS requested but msgfmt/libintl are unusable; disabling")
    endif()
endif()

# ---------------------------------------------------------------------------
# Generate config.h / config-paths.h
# ---------------------------------------------------------------------------

configure_file("${CMAKE_CURRENT_SOURCE_DIR}/cmake/config-paths.h.in"
               "${WM_GENERATED_DIR}/config-paths.h" @ONLY)
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/cmake/config.h.in"
               "${WM_GENERATED_DIR}/config.h" @ONLY)

# src/wconfig.h has no substitutions - autoconf merely copied it.  It has to
# land in <builddir>/src because tools/ and src/apps/ reach for it as
# "../src/wconfig.h", which the preprocessor resolves against -I<builddir>/generated.
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/src/wmaker/wconfig.h.in"
               "${CMAKE_BINARY_DIR}/src/wconfig.h" COPYONLY)

# ---------------------------------------------------------------------------
# Common compile settings
# ---------------------------------------------------------------------------

add_library(wmaker_common INTERFACE)
target_include_directories(wmaker_common INTERFACE
    "${WM_GENERATED_DIR}"
    "${WM_GENERATED_DIR}/WINGs"
    "${CMAKE_SOURCE_DIR}/lib/WINGs"
    "${CMAKE_SOURCE_DIR}/lib/WINGs/WINGs"
    "${CMAKE_SOURCE_DIR}/lib/wrlib"
    ${X11_INCLUDE_DIR})
target_compile_definitions(wmaker_common INTERFACE _GNU_SOURCE)

# This code predates a lot of modern diagnostics; keep the noise down but do
# not silence anything that points at a real defect.
add_compile_options(
    -Wall
    -Wno-unused-parameter
    -Wno-deprecated-declarations
    -Wno-format-truncation
    -Wno-stringop-truncation)

# ---------------------------------------------------------------------------
# Subdirectories
# ---------------------------------------------------------------------------

add_subdirectory(lib/wrlib)
add_subdirectory(lib/WINGs)
add_subdirectory(src)
add_subdirectory(data)
add_subdirectory(docs/man)

if(WMAKER_BUILD_WMLIB)
    add_subdirectory(lib/wmlib)
endif()
if(WMAKER_BUILD_UTILS)
    add_subdirectory(tools)
endif()
if(I18N)
    wm_add_translations(nls_wmaker  DOMAIN WindowMaker PO_DIR "${CMAKE_SOURCE_DIR}/src/wmaker/po"           LOCALEDIR "${WM_STAGE_LOCALE}")
    wm_add_translations(nls_wings   DOMAIN WINGs       PO_DIR "${CMAKE_SOURCE_DIR}/lib/WINGs/po"     LOCALEDIR "${WM_STAGE_LOCALE}")
    wm_add_translations(nls_wraster DOMAIN WRaster     PO_DIR "${CMAKE_SOURCE_DIR}/lib/wrlib/po"     LOCALEDIR "${WM_STAGE_LOCALE}")
    wm_add_translations(nls_util    DOMAIN wmgenmenu   PO_DIR "${CMAKE_SOURCE_DIR}/tools/po"      LOCALEDIR "${WM_STAGE_LOCALE}")
    if(WMAKER_BUILD_WPREFS)
        wm_add_translations(nls_wprefs DOMAIN WPrefs   PO_DIR "${CMAKE_SOURCE_DIR}/src/apps/WPrefs/po" LOCALEDIR "${WM_STAGE_LOCALE}")
    endif()

    install(DIRECTORY "${WM_STAGE_LOCALE}/"
            DESTINATION ${WM_LOCALEDIR}
            FILES_MATCHING PATTERN "*.mo")
endif()

# ---------------------------------------------------------------------------
# Development helper: environment script for the staged tree
# ---------------------------------------------------------------------------

if(WMAKER_DEV_TREE)
    configure_file("${CMAKE_CURRENT_SOURCE_DIR}/cmake/use-wmaker.sh.in"
                   "${WM_STAGE_PREFIX}/use-wmaker.sh" @ONLY
                   FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                                    GROUP_READ GROUP_EXECUTE
                                    WORLD_READ WORLD_EXECUTE)
endif()

# ---------------------------------------------------------------------------
# Configuration summary
# ---------------------------------------------------------------------------

message(STATUS "")
message(STATUS "Window Maker ${PROJECT_VERSION} configured:")
message(STATUS "  build type .......... ${CMAKE_BUILD_TYPE}")
message(STATUS "  staged tree ......... ${WM_PREFIX}")
message(STATUS "  shared libraries .... ${BUILD_SHARED_LIBS}")
message(STATUS "  X extensions ........ shape=${USE_XSHAPE} shm=${USE_XSHM} xinerama=${USE_XINERAMA} randr=${USE_RANDR} xres=${USE_XRES} xmu=${HAVE_LIBXMU}")
message(STATUS "  image formats ....... xpm=${USE_XPM} png=${USE_PNG} jpeg=${USE_JPEG} tiff=${USE_TIFF} gif=${USE_GIF} webp=${USE_WEBP} magick=${USE_MAGICK}")
message(STATUS "  icon extension ...... ${WM_ICONEXT}")
message(STATUS "  pango ............... ${USE_PANGO}")
message(STATUS "  translations ........ ${I18N}")
message(STATUS "  WPrefs .............. ${WMAKER_BUILD_WPREFS}")
message(STATUS "  utilities ........... ${WMAKER_BUILD_UTILS}")
message(STATUS "  WINGs examples ...... ${WMAKER_BUILD_EXAMPLES}")
message(STATUS "")
