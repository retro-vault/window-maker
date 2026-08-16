# WMTableView - a table widget that is not part of libWINGs proper.  Upstream
# shipped it without ever compiling it; building the demo here keeps both the
# widget and its example from silently rotting the way notest.c did.

add_library(WINGsExtra STATIC
    wtableview.c
    wtabledelegates.c)

target_include_directories(WINGsExtra PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(WINGsExtra PUBLIC wmaker_common WINGs WUtil)

add_executable(wings_tableview tableview.c)
set_target_properties(wings_tableview PROPERTIES OUTPUT_NAME wings-tableview)
target_link_libraries(wings_tableview PRIVATE
    WINGsExtra WINGs WUtil wraster ${X11_LIBRARIES})
