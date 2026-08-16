# Building Window Maker with CMake

*All paths below are relative to the repository root.*

CMake is the **only** build system in this tree. The autotools build has been
removed: there is no `configure`, `configure.ac`, `Makefile.am`, `Makefile.in`,
`m4/`, `ltmain.sh` or `script/`. `cmake` itself is the only program the build
runs, apart from `msgfmt` when translations are enabled.

Every generation step was reimplemented rather than delegated:

| Job | autotools did it with | CMake build does it with |
| --- | --- | --- |
| `config.h` | `configure` + `autoheader` | `check_include_file` / `check_symbol_exists` / `check_c_source_compiles` probes, `cmake/config.h.in` |
| `config-paths.h` | `echo` lines in `Makefile.am` | `cmake/config-paths.h.in` |
| `wraster.h`, `WINGsP.h` | `script/replace-ac-keywords.sh` | `wm_filter_template()` in `cmake/WMakerHelpers.cmake` |
| menus, `WMState`, `wmaker.inst`, `WPrefs.desktop` | `sed` rules | `wm_expand_file()` |
| `wmaker.1`, `wmsetbg.1` | `script/replace-ac-keywords.sh` | `wm_filter_template()` + `wm_expand_file()` |
| `Default.iconset` | `grep` rule | `wm_grep_lines()` |
| source lists | `Makefile.am` | explicit lists in each `CMakeLists.txt` |
| translations | `po/Makefile.am` | `wm_add_translations()` |

The removed files were moved, not deleted, to `wmaker-autotools/` alongside the
repository, with their original relative paths intact — restoring the old build is a matter of copying
that tree back over this one.

Two pieces of upstream maintainer tooling went with it and have no CMake
equivalent: `make update-lang` (refreshing `.po` files from sources, via
`script/generate-po-from-template.sh` and `xgettext`) and the `make check`
source lints under `script/`. The `.po` files themselves are still compiled and
installed; only the regeneration workflow is gone.

## Source layout

```
CMakeLists.txt      top-level build: probes, feature options, path layout
cmake/              helper functions and the generated-file templates
lib/wrlib/          libwraster - image loading, conversion, rendering
lib/WINGs/          libWINGs (widgets) + libWUtil (toolkit-free utilities)
                      WINGs/    public headers
                      Tests/    widget demo programs
                      Examples/ example applications
                      Extras/   WMTableView widget + demo
lib/wmlib/          libWMaker - application-menu protocol client
                      test/     libWMaker demo (wmlib-wtest)
src/wmaker/         the window manager itself
src/apps/           graphical applications, one subdirectory each
                      WPrefs/    preferences editor
                      wmagnify/  screen magnifier
                      wmiv/      image viewer
tools/              command-line tools and helper scripts
                      config/   defaults database, styles, icon sets
                      menu/     menu generators
                      desktop/  clients acting on a running X session
                      scripts/  shell and Perl helpers
data/               runtime data, one subdirectory per installed location
                      WindowMaker/ menus, styles, icons, global defaults
                      WINGs/       widget artwork
                      WPrefs/      WPrefs panel icons
docs/               documentation (docs/README.md is the index)
                      building/  this guide
                      using/     FAQ, i18n, cursors
                      man/       manual page sources
                      development/ history, credits, contributor guides
                    Translations live beside the component they translate:
                    src/wmaker/po, src/apps/WPrefs/po, lib/WINGs/po,
                    lib/wrlib/po and tools/po.
```

## Requirements

- C compiler with GNU extensions (the sources use nested functions)
- CMake 3.16+
- pkg-config
- X11 development libraries: `libX11`, `libXext`, `libXinerama`, `libXmu`,
  `libXpm`, `libXft`, `fontconfig`
- Optional image libraries, auto-detected: `libpng`, `libjpeg`, `libtiff`,
  `giflib`, `libwebp`
- Optional: `gettext` (translations), `libexif` (`wmiv`), `pango` (text layout),
  `libXrandr`, `MagickWand`
- For the nested development session: `Xephyr`, `xdpyinfo`, `xprop`

Debian/Ubuntu:

```bash
sudo apt install -y build-essential cmake pkg-config gettext \
    libx11-dev libxext-dev libxinerama-dev libxmu-dev libxpm-dev \
    libxft-dev libfontconfig-dev \
    libpng-dev libjpeg-dev libtiff-dev libgif-dev libwebp-dev \
    xserver-xephyr x11-utils
```

## Build

```bash
cmake -S . -B build
cmake --build build -j"$(nproc)"
```

Object files stay in `build/`. Everything you can run lands in `bin/`, laid out
like an install prefix:

```
bin/bin          wmaker, WPrefs, the utilities, the WINGs demos
bin/lib          libwraster, libWINGs, libWUtil, libWMaker + pkgconfig/
bin/include      wraster.h, WMaker.h, WINGs/{WINGs,WUtil,WINGsP}.h
bin/share/WindowMaker   menus, styles, icons, pixmaps, backgrounds, themes
bin/share/WINGs         widget artwork loaded at startup
bin/share/WPrefs        WPrefs artwork (tiff/ and xpm/)
bin/share/locale        compiled .mo catalogues
bin/share/man           manual pages (man1 + cs/ru/sk translations)
bin/etc/WindowMaker     global defaults
bin/use-wmaker.sh       environment helper
```

The binaries carry an RPATH pointing at `bin/lib`, so they run without
`LD_LIBRARY_PATH`. Compile-time paths (`PKGDATADIR`, `PKGCONFDIR`, ...) point
into this tree too, which is what makes it runnable straight from the checkout.

To put it on your `PATH`:

```bash
source ./bin/use-wmaker.sh
```

That also sets `WMAKER_USER_ROOT` to `<repo>/.wmaker-home/GNUstep`, so
experiments never touch your real `~/GNUstep`.

## Running in Xephyr

```bash
./.vscode/wmaker-session-start.sh      # Xephyr on :3 + wmaker + watchdog
DISPLAY=:3 ./bin/bin/wtest             # any WINGs program
./.vscode/wmaker-session-stop.sh
```

The first start runs `wmaker.inst --batch` to populate the private GNUstep
tree. `WMAKER_DISPLAY` and `WMAKER_SCREEN` override the display and geometry.

`--xephyr-only` starts the nested server without a window manager — that is
what you want when `wmaker` itself is the program under the debugger.

The watchdog terminates any staged application still running on that display
(and the `gdb` that launched it) when the window manager or Xephyr goes away,
so a closed session cannot leave the IDE waiting on a debug session forever.

## VS Code

`.vscode/tasks.json` and `.vscode/launch.json` wire the above up:

- **build** (default build task) — configure + build
- **wmaker: start / stop session** — the nested session
- **wmaker: reset user configuration** — delete `.wmaker-home`
- **Debug wmaker (Xephyr)** — Xephyr only, `wmaker` under gdb
- **Debug WPrefs (WINGs app)** — full session, WPrefs under gdb
- **Debug WINGs app (pick)** — full session, pick from `wtest`, `wmquery`,
  `wmfile`, `testmywidget`, `fontl`, `puzzle`, `colorpick`, `wmagnify`, `wmiv`

`compile_commands.json` is exported into `build/` for clangd/IntelliSense.

## Developing against WINGs

The demos under `lib/WINGs/Tests` and `lib/WINGs/Examples` are the fastest way
in; `src/apps/WPrefs` is the largest real WINGs application in the tree. To add one
of your own, drop it in `lib/WINGs/Examples/` and add it to the list in
`lib/WINGs/Examples/CMakeLists.txt`.

`lib/wmlib/test/` holds `wmlib-wtest`, a demo of the separate `libWMaker`
application-menu protocol (not WINGs), and `lib/wrlib/tests/` holds four small
`wraster-*` programs that drive the raster library directly.

For a program outside this tree, the staged `bin/` is a complete SDK:

```bash
source ./bin/use-wmaker.sh
cc myapp.c $(pkg-config --cflags --libs WINGs wrlib) -o myapp
```

## Options

| Option | Default | Meaning |
| --- | --- | --- |
| `WMAKER_DEV_TREE` | `ON` | Bake the staged tree's paths into the binaries |
| `WMAKER_STAGE_DIR` | *(empty)* | Staging prefix; empty means `<repo>/bin` for a dev tree, `<builddir>/stage` otherwise |
| `BUILD_SHARED_LIBS` | `ON` | Shared vs static libraries |
| `WMAKER_ANIMATIONS` | `ON` | Animations |
| `WMAKER_MWM_HINTS` | `ON` | Motif WM hints |
| `WMAKER_XDND` | `ON` | Drag-and-drop onto the dock |
| `WMAKER_MODELOCK` | `OFF` | XKB language modelock |
| `WMAKER_WMREPLACE` | `OFF` | ICCCM window-manager replacement |
| `WMAKER_USERMENU` | `OFF` | Per-application user menus |
| `WMAKER_RANDR` | `OFF` | RandR extension |
| `WMAKER_PANGO` | `OFF` | Pango text layout in WINGs |
| `WMAKER_MAGICK` | `OFF` | MagickWand image loading |
| `WMAKER_NLS` | `ON` | Compile translations |
| `WMAKER_BUILD_WPREFS` | `ON` | Build the WPrefs application |
| `WMAKER_BUILD_UTILS` | `ON` | Build the command-line utilities |
| `WMAKER_BUILD_WMLIB` | `ON` | Build libWMaker |
| `WMAKER_BUILD_EXAMPLES` | `ON` | Build the WINGs demos |

The defaults follow `configure.ac`, so a CMake build has the same feature set
the autotools build would have given you.

## System install

Paths are compiled into the binaries, so the prefix has to be chosen at
**configure** time — `cmake --install --prefix` cannot relocate an existing
build:

```bash
cmake -S . -B build -DWMAKER_DEV_TREE=OFF -DCMAKE_INSTALL_PREFIX=/usr/local
cmake --build build -j"$(nproc)"
sudo cmake --install build
sudo ldconfig
```

A non-dev build stages into `<builddir>/stage` rather than `bin/`, so it cannot
overwrite a development tree with binaries that look for their data under the
install prefix; `cmake --install` copies from there to the locations the
binaries actually reference. `DESTDIR` works as usual for packaging.
