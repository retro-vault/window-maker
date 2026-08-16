#!/usr/bin/env bash
#
# Bring up a nested Window Maker session for development:
#
#   Xephyr on $WMAKER_DISPLAY  ->  wmaker  ->  watchdog
#
# The session uses a private GNUstep tree inside the checkout
# (<repo>/.wmaker-home/GNUstep), so it never touches your real desktop
# configuration.  Safe to run repeatedly: existing pieces are reused.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DISPLAY_NUM="${WMAKER_DISPLAY:-:3}"
SCREEN_SIZE="${WMAKER_SCREEN:-1280x800}"

# --xephyr-only brings up just the nested server: that is what you want when
# wmaker itself is the program under the debugger.
XEPHYR_ONLY=0
if [ "${1:-}" = "--xephyr-only" ]; then
  XEPHYR_ONLY=1
fi

STAGE_DIR="$ROOT_DIR/bin"
USER_ROOT="${WMAKER_USER_ROOT:-$ROOT_DIR/.wmaker-home/GNUstep}"

LOG_DIR="$ROOT_DIR/.vscode"
XE_PID_FILE="$LOG_DIR/.wmaker-xephyr.pid"
WM_PID_FILE="$LOG_DIR/.wmaker-wm.pid"
WATCHDOG_PID_FILE="$LOG_DIR/.wmaker-watchdog.pid"

mkdir -p "$LOG_DIR"

for tool in Xephyr xdpyinfo xprop; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "$tool is required but not installed." >&2
    exit 1
  }
done

if [ ! -x "$STAGE_DIR/bin/wmaker" ]; then
  echo "wmaker has not been built yet - run the 'build' task first." >&2
  exit 1
fi

export PATH="$STAGE_DIR/bin:$PATH"
export LD_LIBRARY_PATH="$STAGE_DIR/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export WMAKER_USER_ROOT="$USER_ROOT"

cleanup_pid_file_if_dead() {
  local pid_file="$1" pid
  if [ -f "$pid_file" ]; then
    pid="$(cat "$pid_file" 2>/dev/null || true)"
    if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
      rm -f "$pid_file"
    fi
  fi
}

cleanup_pid_file_if_dead "$XE_PID_FILE"
cleanup_pid_file_if_dead "$WM_PID_FILE"
cleanup_pid_file_if_dead "$WATCHDOG_PID_FILE"

# --- nested X server ------------------------------------------------------

if ! xdpyinfo -display "$DISPLAY_NUM" >/dev/null 2>&1; then
  (
    setsid Xephyr "$DISPLAY_NUM" -screen "$SCREEN_SIZE" -ac -resizeable \
      >"$LOG_DIR/wmaker-xephyr.log" 2>&1 < /dev/null &
    echo $! > "$XE_PID_FILE"
  )

  for _ in $(seq 1 40); do
    xdpyinfo -display "$DISPLAY_NUM" >/dev/null 2>&1 && break
    sleep 0.1
  done
fi

if ! xdpyinfo -display "$DISPLAY_NUM" >/dev/null 2>&1; then
  echo "Failed to start Xephyr on $DISPLAY_NUM; see $LOG_DIR/wmaker-xephyr.log" >&2
  exit 1
fi

# --- per-user configuration ----------------------------------------------

if [ ! -f "$USER_ROOT/Defaults/WindowMaker" ]; then
  echo "Creating private Window Maker configuration in $USER_ROOT"
  mkdir -p "$USER_ROOT"
  "$STAGE_DIR/bin/wmaker.inst" --batch >"$LOG_DIR/wmaker-inst.log" 2>&1 || {
    echo "wmaker.inst failed; see $LOG_DIR/wmaker-inst.log" >&2
    exit 1
  }
fi

if [ "$XEPHYR_ONLY" -eq 1 ]; then
  echo "Xephyr ready on DISPLAY=$DISPLAY_NUM (no window manager started)"
  echo "  user root ... $USER_ROOT"
  exit 0
fi

# --- the window manager ---------------------------------------------------

if [ ! -f "$WM_PID_FILE" ]; then
  (
    DISPLAY="$DISPLAY_NUM" setsid "$STAGE_DIR/bin/wmaker" \
      >"$LOG_DIR/wmaker-wm.log" 2>&1 < /dev/null &
    echo $! > "$WM_PID_FILE"
  )

  # Wait until wmaker owns the screen.  Without this handshake an app started
  # by the debugger can map its window before the WM redirects, and ends up
  # undecorated in the top-left corner.
  wm_ready=0
  for _ in $(seq 1 120); do
    if ! kill -0 "$(cat "$WM_PID_FILE")" 2>/dev/null; then
      echo "wmaker failed to start; see $LOG_DIR/wmaker-wm.log" >&2
      exit 1
    fi
    if DISPLAY="$DISPLAY_NUM" xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null \
         | grep -q "window id"; then
      wm_ready=1
      break
    fi
    sleep 0.1
  done

  if [ "$wm_ready" -ne 1 ]; then
    echo "wmaker did not become ready on $DISPLAY_NUM; see $LOG_DIR/wmaker-wm.log" >&2
    exit 1
  fi
fi

# Brief grace period so wmaker finishes reading its defaults before the
# debugged application maps its first window.
sleep "${WMAKER_WM_GRACE_SECONDS:-1}"

# --- watchdog -------------------------------------------------------------

if [ ! -f "$WATCHDOG_PID_FILE" ]; then
  (
    setsid "$ROOT_DIR/.vscode/wmaker-wm-watchdog.sh" \
      "$DISPLAY_NUM" "$ROOT_DIR" "$WM_PID_FILE" "$XE_PID_FILE" \
      "$WATCHDOG_PID_FILE" "$LOG_DIR/wmaker-watchdog.log" \
      >> "$LOG_DIR/wmaker-watchdog.log" 2>&1 < /dev/null &
    echo $! > "$WATCHDOG_PID_FILE"
  )
fi

echo "Window Maker session ready on DISPLAY=$DISPLAY_NUM"
echo "  stage ....... $STAGE_DIR"
echo "  user root ... $USER_ROOT"
