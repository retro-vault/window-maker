# Small programs exercising libwraster directly: gradients, rotation, drawing
# primitives and a minimal image viewer.  Prefixed so they cannot collide with
# the installed tools.

foreach(_prog testdraw testgrad testrot view)
    add_executable(wraster_${_prog} ${_prog}.c)
    set_target_properties(wraster_${_prog} PROPERTIES OUTPUT_NAME wraster-${_prog})
    target_include_directories(wraster_${_prog} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
    target_link_libraries(wraster_${_prog} PRIVATE
        wmaker_common wraster ${X11_LIBRARIES} ${WM_LIBM})
endforeach()
