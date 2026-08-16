#!/usr/bin/env bash
#
# If the window manager or the nested X server goes away, terminate every
# staged application still running on that display - and the debugger that
# launched it.  Without this, closing the session leaves the IDE waiting on a
# debug session that can never finish.
set -euo pipefail

if [ "$#" -lt 6 ]; then
  echo "usage: $0 <display> <root_dir> <wm_pid_file> <xe_pid_file> <watchdog_pid_file> <log_file>" >&2
  exit 2
fi

DISPLAY_NUM="$1"
ROOT_DIR="$2"
WM_PID_FILE="$3"
XE_PID_FILE="$4"
WATCHDOG_PID_FILE="$5"
LOG_FILE="$6"

STAGE_BIN="$ROOT_DIR/bin/bin"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

trap 'rm -f "$WATCHDOG_PID_FILE"' EXIT

pid_alive() {
  local pid="$1"
  [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}

# True when the process was launched from the staged tree - that is how we tell
# "our" applications apart from anything else the user has running.
pid_is_staged_app() {
  local pid="$1" exe
  exe="$(readlink -f "/proc/$pid/exe" 2>/dev/null || true)"
  case "$exe" in
    "$STAGE_BIN"/*) return 0 ;;
    *) return 1 ;;
  esac
}

pid_on_our_display() {
  grep -zqx "DISPLAY=$DISPLAY_NUM" "/proc/$1/environ" 2>/dev/null
}

# Walk up from an application to the gdb that spawned it, so the debug session
# ends instead of hanging.
kill_debugger_ancestors_for_pid() {
  local pid="$1" sig="$2" cur ppid exe base

  cur="$pid"
  for _ in 1 2 3 4 5 6; do
    ppid="$(awk '{print $4}' "/proc/$cur/stat" 2>/dev/null || true)"
    [ -n "$ppid" ] && [ "$ppid" -gt 1 ] || break

    exe="$(readlink -f "/proc/$ppid/exe" 2>/dev/null || true)"
    base="$(basename "$exe" 2>/dev/null || true)"
    if [ "$base" = "gdb" ] || [ "$base" = "gdbserver" ]; then
      log "matched debugger ancestor pid=$ppid for app_pid=$pid (SIG$sig)"
      kill "-$sig" "$ppid" 2>/dev/null || true
      break
    fi

    cur="$ppid"
  done
}

kill_staged_clients() {
  local sig="$1" pid
  for pid in /proc/[0-9]*; do
    pid="${pid#/proc/}"
    pid_is_staged_app "$pid" || continue
    pid_on_our_display "$pid" || continue
    log "terminating staged app pid=$pid (SIG$sig)"
    kill_debugger_ancestors_for_pid "$pid" "$sig"
    kill "-$sig" "$pid" 2>/dev/null || true
  done
}

log "watchdog started for DISPLAY=$DISPLAY_NUM"

wm_missing_count=0
while true; do
  WM_PID="$(cat "$WM_PID_FILE" 2>/dev/null || true)"
  XE_PID="$(cat "$XE_PID_FILE" 2>/dev/null || true)"

  wm_ok=0; xe_ok=0

  pid_alive "$WM_PID" && wm_ok=1
  pid_alive "$XE_PID" && xe_ok=1

  # The PID files only cover sessions we started; also confirm that somebody
  # still claims the screen, which catches a wmaker that exited via its menu.
  if DISPLAY="$DISPLAY_NUM" xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | grep -q "window id"; then
    wm_missing_count=0
  else
    wm_missing_count=$((wm_missing_count + 1))
  fi

  if [ "$wm_ok" -eq 0 ] || [ "$xe_ok" -eq 0 ] || [ "$wm_missing_count" -ge 3 ]; then
    log "session lost (wm=$wm_ok xephyr=$xe_ok miss=$wm_missing_count); cleaning up clients"
    kill_staged_clients TERM
    sleep 0.25
    kill_staged_clients KILL
    exit 0
  fi

  sleep 0.5
done
