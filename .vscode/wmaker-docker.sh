#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STATE="$ROOT/build/docker"
IMAGE=wischner/gcc-x86_64-linux-x11
NAME="wmaker-$(printf '%s' "$ROOT" | sha256sum | cut -c1-12)"
case "${1:-}" in
  stop)
    docker rm -f "$NAME" >/dev/null 2>&1 || true
    exit ;;
  tool)
    shift
    if [[ -f /.dockerenv ]]; then exec "$@"; fi
    exec docker exec -i --workdir "$PWD" \
      --env "PKG_CONFIG_SYSROOT_DIR=${PKG_CONFIG_SYSROOT_DIR:-}" \
      --env "PKG_CONFIG_LIBDIR=${PKG_CONFIG_LIBDIR:-}" "$NAME" "$@" ;;
  debug)
    shift
    exec docker exec -i "$NAME" bash "$ROOT/.vscode/wmaker-container.sh" debug "$ROOT" "$@" ;;
  build|prepare) ACTION="$1" ;;
  *) echo "Usage: $0 {build|prepare|debug|stop|tool COMMAND...}" >&2; exit 2 ;;
esac
command -v cmake >/dev/null
mkdir -p "$STATE"
"$0" stop
args=(--detach --name "$NAME" --user "$(id -u):$(id -g)"
  --mount "type=bind,src=$ROOT,dst=$ROOT" --workdir "$ROOT"
  --env "HOME=$ROOT/.wmaker-home" --env "DISPLAY=${DISPLAY:-}" \
  --env "WMAKER_DISPLAY=${WMAKER_DISPLAY:-:3}" --env "WMAKER_SCREEN=${WMAKER_SCREEN:-1280x800}")
if [[ "$ACTION" = prepare ]]; then
  if [[ ! "${DISPLAY:-}" =~ ^:([0-9]+)(\.[0-9]+)?$ ]]; then
    echo 'Set DISPLAY to a local X11/Xwayland display (for example :0).' >&2; exit 1
  fi
  HOST_X="${BASH_REMATCH[1]}"
  [[ "${WMAKER_DISPLAY:-:3}" != ":$HOST_X" ]] || { echo 'Host and nested displays must differ.' >&2; exit 1; }
  args+=(--mount "type=bind,src=/tmp/.X11-unix/X$HOST_X,dst=/tmp/.X11-unix/X$HOST_X,readonly")
  AUTH="${XAUTHORITY:-$HOME/.Xauthority}"
  if [[ -f "$AUTH" ]]; then
    args+=(--mount "type=bind,src=$AUTH,dst=/tmp/wmaker-host.xauth,readonly" --env XAUTHORITY=/tmp/wmaker-host.xauth)
  fi
fi
CMAKE_ROOT="$(cmake --system-information | sed -n 's/^CMAKE_ROOT "\(.*\)"$/\1/p')"
args+=(--mount "type=bind,src=$CMAKE_ROOT,dst=$CMAKE_ROOT,readonly")
args+=(--platform linux/amd64 --tmpfs /tmp/.X11-unix:rw,mode=1777)
args+=(--hostname "$(hostname)")
docker run "${args[@]}" --entrypoint /bin/bash "$IMAGE" -c 'while :; do sleep 3600; done' >/dev/null
trap '"$0" stop' ERR
IMAGE_ID="$(docker inspect --format '{{.Image}}' "$NAME")"
if [[ ! -f "$STATE/image-id" ]] || [[ "$(cat "$STATE/image-id")" != "$IMAGE_ID" ]]; then
  rm -rf "$STATE/sysroot" "$STATE/cmake"
  mkdir -p "$STATE/sysroot/usr"
  docker cp "$NAME:/usr/include" "$STATE/sysroot/usr/"
  docker cp "$NAME:/usr/lib" "$STATE/sysroot/usr/"
  ln -s usr/lib "$STATE/sysroot/lib"
  printf '%s\n' "$IMAGE_ID" > "$STATE/image-id"
fi
while IFS= read -r -d '' link; do
  target="$(readlink "$link")"
  if [[ "$target" = /* ]]; then
    ln -sfn "$(realpath --relative-to="$(dirname "$link")" -m "$STATE/sysroot$target")" "$link"
  fi
done < <(find "$STATE/sysroot" -type l -print0)
mkdir -p "$STATE/tools"
for tool in gcc make pkg-config ar ranlib ld msgfmt; do
  printf '#!/usr/bin/env bash\nexec %q tool %q "$@"\n' "$ROOT/.vscode/wmaker-docker.sh" "$tool" > "$STATE/tools/$tool"
  chmod +x "$STATE/tools/$tool"
done
NLS=OFF
if docker exec "$NAME" sh -c 'command -v msgfmt >/dev/null'; then NLS=ON; fi
# pkg-config must return the snapshot paths so host CMake can validate them.
export PKG_CONFIG_SYSROOT_DIR="$STATE/sysroot"
export PKG_CONFIG_LIBDIR=/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig
cmake -S "$ROOT" -B "$STATE/cmake" -G 'Unix Makefiles' \
  -DCMAKE_BUILD_TYPE=Debug -DCMAKE_C_COMPILER="$STATE/tools/gcc" \
  -DCMAKE_AR="$STATE/tools/ar" -DCMAKE_RANLIB="$STATE/tools/ranlib" -DCMAKE_LINKER="$STATE/tools/ld" \
  -DCMAKE_MAKE_PROGRAM="$STATE/tools/make" \
  -DCMAKE_FIND_ROOT_PATH="$STATE/sysroot" \
  -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
  -DWMAKER_NLS="$NLS" -DMSGFMT_EXECUTABLE="$STATE/tools/msgfmt" \
  -DPKG_CONFIG_EXECUTABLE="$STATE/tools/pkg-config" \
  -DWMAKER_DEV_TREE=ON -DBUILD_SHARED_LIBS=ON -DWMAKER_RANDR=ON \
  -DWMAKER_BUILD_WPREFS=ON -DWMAKER_BUILD_UTILS=ON \
  -DWMAKER_BUILD_WMLIB=ON -DWMAKER_BUILD_EXAMPLES=ON
cmake --build "$STATE/cmake" --parallel "$(getconf _NPROCESSORS_ONLN)"
if [[ "$ACTION" = prepare ]]; then
  docker exec "$NAME" bash "$ROOT/.vscode/wmaker-container.sh" start "$ROOT"
fi
if [[ "$ACTION" = build ]]; then "$0" stop; fi
trap - ERR
