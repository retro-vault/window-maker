#!/usr/bin/env bash
set -euo pipefail
ACTION="$1"
ROOT="$2"
shift 2
export PATH="$ROOT/bin/bin:$PATH"
export LD_LIBRARY_PATH="$ROOT/bin/lib"
export WMAKER_USER_ROOT="$ROOT/.wmaker-home/GNUstep"
NESTED="${WMAKER_DISPLAY:-:3}"
STATE="$ROOT/build/docker"
case "$ACTION" in
  start)
    [[ -n "${DISPLAY:-}" ]] || { echo 'DISPLAY must identify your host X11/Xwayland server.' >&2; exit 1; }
    mkdir -p "$WMAKER_USER_ROOT"
    nohup Xephyr "$NESTED" -screen "${WMAKER_SCREEN:-1280x800}" -ac -nolisten tcp -resizeable >"$STATE/xephyr.log" 2>&1 </dev/null &
    echo "$!" > "$STATE/xephyr.pid"
    ready=0
    for ((i=0;i<100;i++)); do
      kill -0 "$(cat "$STATE/xephyr.pid")" 2>/dev/null || break
      if xdpyinfo -display "$NESTED" >/dev/null 2>&1; then ready=1; break; fi
      sleep 0.1
    done
    if [[ "$ready" = 0 ]]; then cat "$STATE/xephyr.log" >&2; exit 1; fi
    if [[ ! -f "$WMAKER_USER_ROOT/Defaults/WindowMaker" ]]; then
      wmaker.inst --batch >"$STATE/wmaker-inst.log" 2>&1 || { cat "$STATE/wmaker-inst.log" >&2; exit 1; }
    fi ;;
  debug)
    export DISPLAY="$NESTED"
    debugger=$$
    # Closing Xephyr also ends the debug session; VS Code's post task removes
    # the container and all remaining session processes.
    (
      while kill -0 "$(cat "$STATE/xephyr.pid")" 2>/dev/null && xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; do sleep 0.5; done
      kill -TERM "$debugger" 2>/dev/null || true
    ) </dev/null >/dev/null 2>&1 &
    # cppdbg supplies the debugger and flags as one shell command.
    if [[ "$#" = 1 ]]; then exec /bin/sh -c "exec $1"; fi
    exec "$@" ;;
esac
