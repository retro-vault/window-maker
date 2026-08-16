#!/usr/bin/env bash
#
# Tear down the nested Window Maker session started by wmaker-session-start.sh.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
XE_PID_FILE="$ROOT_DIR/.vscode/.wmaker-xephyr.pid"
WM_PID_FILE="$ROOT_DIR/.vscode/.wmaker-wm.pid"
WATCHDOG_PID_FILE="$ROOT_DIR/.vscode/.wmaker-watchdog.pid"

stop_from_pid_file() {
  local pid_file="$1" pid
  if [ -f "$pid_file" ]; then
    pid="$(cat "$pid_file" 2>/dev/null || true)"
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      sleep 0.2
      kill -9 "$pid" 2>/dev/null || true
    fi
    rm -f "$pid_file"
  fi
}

# Watchdog first, so it does not react to the window manager going away.
stop_from_pid_file "$WATCHDOG_PID_FILE"
stop_from_pid_file "$WM_PID_FILE"
stop_from_pid_file "$XE_PID_FILE"

echo "Window Maker session stopped"
