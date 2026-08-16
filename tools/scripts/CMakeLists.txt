# Shell and Perl helpers.  Nothing here is compiled; the runtime helpers are
# staged into bin/ alongside the compiled tools, while the maintainer scripts
# are neither staged nor installed - they are run from the source tree.

# wmaker.inst needs the configured paths patched in.
wm_expand_file("${CMAKE_CURRENT_SOURCE_DIR}/wmaker.inst.in"
               "${CMAKE_BINARY_DIR}/generated/tools/wmaker.inst"
               "#pkgdatadir#" "${WM_PKGDATADIR}"
               "#sysconfdir#" "${WM_PKGCONFDIR}"
               "#version#"    "${PROJECT_VERSION}"
               "#bindir#"     "${WM_BINDIR}")

set(WMAKER_RUNTIME_SCRIPTS
    "${CMAKE_BINARY_DIR}/generated/tools/wmaker.inst"
    "${CMAKE_CURRENT_SOURCE_DIR}/wm-oldmenu2new"
    "${CMAKE_CURRENT_SOURCE_DIR}/wkdemenu.pl")

set(_stamps "")
foreach(_script IN LISTS WMAKER_RUNTIME_SCRIPTS)
    get_filename_component(_base "${_script}" NAME)
    add_custom_command(
        OUTPUT "${WM_STAGE_BIN}/${_base}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${WM_STAGE_BIN}"
        COMMAND ${CMAKE_COMMAND} "-DSRC=${_script}" "-DDSTDIR=${WM_STAGE_BIN}"
                -P "${CMAKE_SOURCE_DIR}/cmake/StageProgram.cmake"
        DEPENDS "${_script}"
        COMMENT "Staging ${_base}"
        VERBATIM)
    list(APPEND _stamps "${WM_STAGE_BIN}/${_base}")
endforeach()

add_custom_target(tool_scripts ALL DEPENDS ${_stamps})

install(PROGRAMS ${WMAKER_RUNTIME_SCRIPTS} DESTINATION ${WM_BINDIR})

# Not staged and not installed, matching what the automake build did:
#
#   bughint              run from the source tree to collect system details
#                        for a bug report (was EXTRA_DIST, never installed)
#   checkpatch.pl        coding-style checker for patches
#   update-changelog.pl  regenerates the ChangeLog from git history
