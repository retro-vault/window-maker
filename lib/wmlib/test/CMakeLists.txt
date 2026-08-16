# Demo client for libWMaker (wmlib) - it talks to Window Maker's application
# menu protocol rather than using WINGs.  Named wmlib-wtest to avoid clashing
# with the unrelated WINGs/Tests/wtest.
#
# notest.c is deliberately not built: it calls a notification API (WMNotifySet,
# WMN_APP_START, ...) that WMaker.h no longer declares.  The automake build
# shipped it via EXTRA_DIST without compiling it, for the same reason.

add_executable(wmlib_wtest wtest.c)
set_target_properties(wmlib_wtest PROPERTIES OUTPUT_NAME wmlib-wtest)
target_link_libraries(wmlib_wtest PRIVATE WMaker wmaker_common ${X11_LIBRARIES})
