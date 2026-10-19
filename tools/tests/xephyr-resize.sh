#!/usr/bin/env bash
# Run in an isolated development container after building the staged tree:
# docker run --rm -v "$PWD:$PWD" -w "$PWD" --entrypoint bash \
#   wischner/gcc-x86_64-linux-x11 tools/tests/xephyr-resize.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TEST_DIR="$(mktemp -d)"
pids=()
cleanup() {
  if ((${#pids[@]})); then kill "${pids[@]}" 2>/dev/null || true; fi
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT
export PATH="$ROOT/bin/bin:$PATH"
export LD_LIBRARY_PATH="$ROOT/bin/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export WMAKER_USER_ROOT="$TEST_DIR/GNUstep"
mkdir -p "$WMAKER_USER_ROOT/Defaults"
cp "$ROOT/bin/etc/WindowMaker/WindowMaker" "$ROOT/bin/etc/WindowMaker/WMState" \
  "$WMAKER_USER_ROOT/Defaults/"
wait_for_display() {
  for ((i=0; i<100; i++)); do
    if xdpyinfo -display "$1" >/dev/null 2>&1; then return; fi
    sleep 0.05
  done
  cat "$TEST_DIR/"*.log
  return 1
}
cc -Wall -Wextra -UNDEBUG "$ROOT/tools/tests/xephyr-resize.c" \
  -o "$TEST_DIR/interaction" -lX11 -l:libXtst.so.6
Xvfb :91 -screen 0 2400x1800x24 >"$TEST_DIR/xvfb.log" 2>&1 &
pids+=("$!")
wait_for_display :91
DISPLAY=:91 Xephyr :92 -screen 800x600 -resizeable -ac >"$TEST_DIR/xephyr.log" 2>&1 &
pids+=("$!")
wait_for_display :92
DISPLAY=:92 wmaker --no-autolaunch >"$TEST_DIR/wmaker.log" 2>&1 &
pids+=("$!")
sleep 2
if ! "$TEST_DIR/interaction" :91 :92; then
  cat "$TEST_DIR/wmaker.log"
  exit 1
fi
kill -0 "${pids[2]}"
