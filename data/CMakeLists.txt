# Runtime data.  Nothing here is compiled; each subdirectory is staged into
# one installed location, which is why they are named after those locations
# rather than after the component that reads them.
#
#   WindowMaker/  -> share/WindowMaker  (+ etc/WindowMaker, share/xsessions)
#   WINGs/        -> share/WINGs        widget artwork libWINGs loads at startup
#   WPrefs/       -> share/WPrefs       WPrefs panel icons

add_subdirectory(WindowMaker)
add_subdirectory(WINGs)

if(WMAKER_BUILD_WPREFS)
    add_subdirectory(WPrefs)
endif()
