# Helper functions shared by the Window Maker CMake build.

# Internal: write <content> to <output>, but only touch the file when the
# content actually changed, so we do not trigger needless rebuilds.
function(_wm_write_if_different output content)
    get_filename_component(_dir "${output}" DIRECTORY)
    file(MAKE_DIRECTORY "${_dir}")
    if(EXISTS "${output}")
        file(READ "${output}" _old)
        if(_old STREQUAL "${content}")
            return()
        endif()
    endif()
    file(WRITE "${output}" "${content}")
endfunction()


# wm_filter_template(<input> <output> ENABLED <keys...> DISABLED <keys...>)
#
# Reimplementation of script/replace-ac-keywords.sh in pure CMake, so the
# build does not depend on a POSIX shell.  Template lines may be prefixed
# with "@KEY@" (keep the line only when KEY is enabled) or "@!KEY@" (keep
# the line only when KEY is disabled); the marker itself is stripped.
function(wm_filter_template input output)
    cmake_parse_arguments(ARG "" "" "ENABLED;DISABLED" ${ARGN})

    file(READ "${input}" _content)

    foreach(_key IN LISTS ARG_ENABLED)
        string(REGEX REPLACE "[^\n]*@!${_key}@[^\n]*\n" "" _content "${_content}")
        string(REPLACE "@${_key}@" "" _content "${_content}")
    endforeach()

    foreach(_key IN LISTS ARG_DISABLED)
        string(REGEX REPLACE "[^\n]*@${_key}@[^\n]*\n" "" _content "${_content}")
        string(REPLACE "@!${_key}@" "" _content "${_content}")
    endforeach()

    set_property(DIRECTORY "${CMAKE_SOURCE_DIR}"
        APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${input}")
    _wm_write_if_different("${output}" "${_content}")
endfunction()


# wm_expand_file(<input> <output> <token> <value> [<token> <value>...])
#
# Plain textual substitution, used for the ".in" files that the automake
# rules processed with sed (menus, WMState, wmaker.inst, ...).
function(wm_expand_file input output)
    file(READ "${input}" _content)
    set(_pairs ${ARGN})
    list(LENGTH _pairs _n)
    if(_n GREATER 0)
        math(EXPR _last "${_n} - 1")
        foreach(_i RANGE 0 ${_last} 2)
            math(EXPR _j "${_i} + 1")
            list(GET _pairs ${_i} _token)
            list(GET _pairs ${_j} _value)
            string(REPLACE "${_token}" "${_value}" _content "${_content}")
        endforeach()
    endif()

    set_property(DIRECTORY "${CMAKE_SOURCE_DIR}"
        APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${input}")
    _wm_write_if_different("${output}" "${_content}")
endfunction()


# wm_grep_lines(<input> <output> <regex> [PROLOGUE <text>] [EPILOGUE <text>])
#
# Keeps the lines of <input> matching <regex>.  Written as an explicit scan
# rather than file(STRINGS)/MATCHALL because the data files contain semicolons,
# which CMake would otherwise treat as list separators.
function(wm_grep_lines input output regex)
    cmake_parse_arguments(ARG "" "PROLOGUE;EPILOGUE" "" ${ARGN})

    file(READ "${input}" _rest)
    set(_out "${ARG_PROLOGUE}")

    while(NOT _rest STREQUAL "")
        string(FIND "${_rest}" "\n" _nl)
        if(_nl LESS 0)
            set(_line "${_rest}")
            set(_rest "")
        else()
            string(SUBSTRING "${_rest}" 0 ${_nl} _line)
            math(EXPR _next "${_nl} + 1")
            string(SUBSTRING "${_rest}" ${_next} -1 _rest)
        endif()
        if(_line MATCHES "${regex}")
            string(APPEND _out "${_line}\n")
        endif()
    endwhile()

    string(APPEND _out "${ARG_EPILOGUE}")
    _wm_write_if_different("${output}" "${_out}")
endfunction()


# wm_copy_file(<input> <output>) - configure-time copy, no substitutions.
function(wm_copy_file input output)
    file(READ "${input}" _content)
    set_property(DIRECTORY "${CMAKE_SOURCE_DIR}"
        APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${input}")
    _wm_write_if_different("${output}" "${_content}")
endfunction()


# wm_stage_files(<target-name> DESTINATION <dir> FILES <files...>)
#
# Copies data files into the staged tree at build time and hangs them off a
# custom target so incremental builds pick up edits to the sources.
function(wm_stage_files name)
    cmake_parse_arguments(ARG "" "DESTINATION" "FILES" ${ARGN})

    set(_stamps "")
    foreach(_file IN LISTS ARG_FILES)
        get_filename_component(_abs "${_file}" ABSOLUTE)
        get_filename_component(_base "${_file}" NAME)
        set(_dst "${ARG_DESTINATION}/${_base}")
        add_custom_command(
            OUTPUT "${_dst}"
            COMMAND ${CMAKE_COMMAND} -E make_directory "${ARG_DESTINATION}"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "${_abs}" "${_dst}"
            DEPENDS "${_abs}"
            COMMENT "Staging ${_base}"
            VERBATIM)
        list(APPEND _stamps "${_dst}")
    endforeach()

    if(_stamps)
        add_custom_target(${name} ALL DEPENDS ${_stamps})
    else()
        add_custom_target(${name} ALL)
    endif()
endfunction()


# wm_add_translations(<target-name> DOMAIN <name> PO_DIR <dir> LOCALEDIR <dir>)
#
# Compiles every .po in PO_DIR into <localedir>/<lang>/LC_MESSAGES/<domain>.mo.
function(wm_add_translations name)
    cmake_parse_arguments(ARG "" "DOMAIN;PO_DIR;LOCALEDIR" "" ${ARGN})

    file(GLOB _pofiles CONFIGURE_DEPENDS "${ARG_PO_DIR}/*.po")

    set(_mofiles "")
    foreach(_po IN LISTS _pofiles)
        get_filename_component(_lang "${_po}" NAME_WE)
        set(_mo "${ARG_LOCALEDIR}/${_lang}/LC_MESSAGES/${ARG_DOMAIN}.mo")
        add_custom_command(
            OUTPUT "${_mo}"
            COMMAND ${CMAKE_COMMAND} -E make_directory "${ARG_LOCALEDIR}/${_lang}/LC_MESSAGES"
            COMMAND ${MSGFMT_EXECUTABLE} -o "${_mo}" "${_po}"
            DEPENDS "${_po}"
            COMMENT "Compiling ${ARG_DOMAIN} translation (${_lang})"
            VERBATIM)
        list(APPEND _mofiles "${_mo}")
    endforeach()

    if(_mofiles)
        add_custom_target(${name} ALL DEPENDS ${_mofiles})
    else()
        add_custom_target(${name} ALL)
    endif()
endfunction()


# wm_stage_glob(<target-name> DESTINATION <dir> PATTERNS <globs...>)
#
# Convenience wrapper around wm_stage_files() for whole data directories.
function(wm_stage_glob name)
    cmake_parse_arguments(ARG "" "DESTINATION" "PATTERNS" ${ARGN})
    # CONFIGURE_DEPENDS so that adding an icon or a style does not require
    # remembering to re-run cmake by hand.
    file(GLOB _files CONFIGURE_DEPENDS ${ARG_PATTERNS})
    wm_stage_files(${name} DESTINATION "${ARG_DESTINATION}" FILES ${_files})
endfunction()
